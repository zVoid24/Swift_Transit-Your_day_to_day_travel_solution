package utils

import (
	"encoding/json"
	"net/http"
)

func (h *Handler) SendData(w http.ResponseWriter, data any, statusCode int) {
	w.WriteHeader(statusCode)
	encoder := json.NewEncoder(w)
	encoder.Encode(data)
}
