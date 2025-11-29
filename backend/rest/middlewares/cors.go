package middlewares

import (
	"bytes"
	"io"
	"net/http"
)

func (h *Handler) Cors(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		// Allow all origins (you can restrict to specific domains)
		w.Header().Set("Access-Control-Allow-Origin", "*")
		w.Header().Set("Access-Control-Allow-Methods", "GET, POST, PUT, DELETE, OPTIONS")
		w.Header().Set("Access-Control-Allow-Headers", "Content-Type, Authorization")
		w.Header().Set("Content-Type", "application/json")

		// Handle preflight request
		if r.Method == http.MethodOptions {
			w.WriteHeader(http.StatusNoContent)
			return
		}

		// Read and reset the body to ensure it's available for the next handler
		body, err := io.ReadAll(r.Body)
		if err != nil {
			http.Error(w, "Failed to read request body", http.StatusInternalServerError)
			return
		}
		// Close the original body
		r.Body.Close()

		// Reassign the body to r.Body for the next handler
		r.Body = io.NopCloser(bytes.NewBuffer(body))

		// Pass the request to the next handler
		next.ServeHTTP(w, r)
	})
}
