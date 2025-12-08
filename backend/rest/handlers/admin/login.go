package admin

import (
	"encoding/json"
	"net/http"
)

type LoginRequest struct {
	Username string `json:"username"`
	Password string `json:"password"`
}

func (h *Handler) Login(w http.ResponseWriter, r *http.Request) {
	var req LoginRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		h.utilHandler.SendError(w, "Invalid request body", http.StatusBadRequest)
		return
	}

	admin, token, err := h.svc.Login(req.Username, req.Password)
	if err != nil {
		h.utilHandler.SendError(w, err.Error(), http.StatusUnauthorized)
		return
	}

	h.utilHandler.SendData(w, map[string]interface{}{
		"admin": admin,
		"token": token,
	}, http.StatusOK)
}
