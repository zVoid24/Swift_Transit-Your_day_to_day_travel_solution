package utils

import (
	"encoding/json"
	"net/http"
)

func (h *Handler) SendError(w http.ResponseWriter, message any, statusCode int) {
	w.WriteHeader(statusCode)
	encoder := json.NewEncoder(w)
	encoder.Encode(message)
}
