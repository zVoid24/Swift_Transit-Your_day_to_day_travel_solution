package utils

import (
	"encoding/base64"
	"encoding/json"
	"fmt"
	"time"
)

func (h *Handler) CreateJWT(data any) (string, error) {
	// Create JWT header
	header := map[string]interface{}{
		"alg": "HS256", // HMAC with SHA-256
		"typ": "JWT",
	}

	// Base64 URL encode the header
	encodedHeader, err := encodeBase64URL(header)
	if err != nil {
		return "", fmt.Errorf("error encoding header: %v", err)
	}

	// Create JWT claims (payload)
	claims := map[string]any{
		"data": data,                                  // Payload data
		"exp":  time.Now().Add(24 * time.Hour).Unix(), // Expiration time (1 day)
		"iat":  time.Now().Unix(),                     // Issued at time
	}

	// Base64 URL encode the claims (payload)
	encodedPayload, err := encodeBase64URL(claims)
	if err != nil {
		return "", fmt.Errorf("error encoding payload: %v", err)
	}

	// Create the unsigned JWT (header + payload)
	unsignedToken := encodedHeader + "." + encodedPayload

	// Create the signature using HMAC SHA256
	signature, err := h.CreateSignature(unsignedToken)
	if err != nil {
		return "", fmt.Errorf("error creating signature: %v", err)
	}

	// Combine header, payload, and signature to form the final JWT
	finalToken := unsignedToken + "." + signature

	return finalToken, nil
}

// encodeBase64URL takes a map, encodes it as JSON, and then base64 URL encodes it.
func encodeBase64URL(data interface{}) (string, error) {
	// Convert data to JSON
	encodedData, err := json.Marshal(data)
	if err != nil {
		return "", fmt.Errorf("error marshaling data: %v", err)
	}

	// Base64 encode the JSON data
	encoded := base64.RawURLEncoding.EncodeToString(encodedData)

	return encoded, nil
}

// createSignature creates a HMAC SHA256 signature for the token using the secret key.
