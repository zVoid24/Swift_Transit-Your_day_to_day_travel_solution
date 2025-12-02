package utils

import (
	"crypto/rand"
	"io"
)

func GenerateOTP(length int) string {
	b := make([]byte, length)
	if _, err := io.ReadAtLeast(rand.Reader, b, length); err != nil {
		// Fallback to a simpler method if crypto/rand fails (unlikely)
		return "123456"
	}
	for i := 0; i < length; i++ {
		b[i] = table[int(b[i])%len(table)]
	}
	return string(b)
}

var table = [...]byte{'1', '2', '3', '4', '5', '6', '7', '8', '9', '0'}
