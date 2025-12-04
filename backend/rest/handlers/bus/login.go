package bus

import (
	"encoding/json"
	"net/http"
)

type LoginRequest struct {
	RegistrationNumber string `json:"registration_number"`
	Password           string `json:"password"`
}

func (h *Handler) Login(w http.ResponseWriter, r *http.Request) {
	var req LoginRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		h.utilHandler.SendError(w, "Invalid request body", http.StatusBadRequest)
		return
	}

	bus, err := h.svc.Login(req.RegistrationNumber, req.Password)
	if err != nil {
		h.utilHandler.SendError(w, "Invalid credentials", http.StatusUnauthorized)
		return
	}

	// Generate JWT or just return success for now.
	// The user didn't explicitly ask for JWT for bus, but "credential like bus number".
	// Let's return the bus info.
	h.utilHandler.SendData(w, bus, http.StatusOK)
}
