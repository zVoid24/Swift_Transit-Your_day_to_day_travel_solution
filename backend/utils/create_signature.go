package utils

import (
	"crypto/hmac"
	"crypto/sha256"
	"encoding/base64"
	"fmt"
)

func (h *Handler) CreateSignature(unsignedToken string) (string, error) {
	// Create HMAC SHA256 hash
	hash := hmac.New(sha256.New, []byte(h.cnf.Secret))
	_, err := hash.Write([]byte(unsignedToken))
	if err != nil {
		return "", fmt.Errorf("error creating signature hash: %v", err)
	}

	// Base64 URL encode the signature
	signature := base64.RawURLEncoding.EncodeToString(hash.Sum(nil))

	return signature, nil
}
