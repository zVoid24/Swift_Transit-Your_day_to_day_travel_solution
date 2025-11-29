package middlewares

import (
	"encoding/base64"
	"encoding/json"
	"net/http"
	"strings"
	"time"
)

func (h *Handler) Authenticate(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		authHeader := r.Header.Get("Authorization")
		if authHeader == "" || !strings.HasPrefix(authHeader, "Bearer ") {
			http.Error(w, "Missing or invalid Authorization header", http.StatusUnauthorized)
			return
		}

		token := strings.TrimPrefix(authHeader, "Bearer ")

		// Split the token into parts
		parts := strings.Split(token, ".")
		if len(parts) != 3 {
			http.Error(w, "Invalid token format", http.StatusUnauthorized)
			return
		}

		headerPart, payloadPart, signaturePart := parts[0], parts[1], parts[2]
		unsignedToken := headerPart + "." + payloadPart

		// Recreate signature
		expectedSignature, err := h.utilHandler.CreateSignature(unsignedToken)
		if err != nil || expectedSignature != signaturePart {
			http.Error(w, "Invalid token signature", http.StatusUnauthorized)
			return
		}

		// Decode payload
		payloadBytes, err := base64.RawURLEncoding.DecodeString(payloadPart)
		if err != nil {
			http.Error(w, "Error decoding token payload", http.StatusUnauthorized)
			return
		}

		var claims map[string]any
		if err := json.Unmarshal(payloadBytes, &claims); err != nil {
			http.Error(w, "Error parsing token claims", http.StatusUnauthorized)
			return
		}

		// Validate expiration
		exp, ok := claims["exp"].(float64)
		if !ok || time.Now().Unix() > int64(exp) {
			http.Error(w, "Token expired", http.StatusUnauthorized)
			return
		}

		// Optionally attach user data to context
		r = r.WithContext(h.utilHandler.AddToContext(r.Context(), claims["data"]))

		next.ServeHTTP(w, r)
	})
}
