package user

import (
	"encoding/json"
	"net/http"
)

type RFIDStatusResponse struct {
	RFID     string `json:"rfid"`
	IsActive bool   `json:"is_active"`
}

type ToggleRFIDRequest struct {
	Active bool `json:"active"`
}

func (h *Handler) GetRFIDStatus(w http.ResponseWriter, r *http.Request) {
	userID := h.utilHandler.GetUserIDFromContext(r.Context())
	user, err := h.svc.GetWithPassword(userID) // Using GetWithPassword as it returns the full user struct including RFID
	if err != nil {
		http.Error(w, "User not found", http.StatusNotFound)
		return
	}

	rfid := ""
	if user.RFID != nil {
		rfid = *user.RFID
	}

	resp := RFIDStatusResponse{
		RFID:     rfid,
		IsActive: user.IsRFIDActive,
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(resp)
}

func (h *Handler) ToggleRFIDStatus(w http.ResponseWriter, r *http.Request) {
	userID := h.utilHandler.GetUserIDFromContext(r.Context())
	var req ToggleRFIDRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		http.Error(w, "Invalid request body", http.StatusBadRequest)
		return
	}

	if err := h.svc.ToggleRFIDStatus(userID, req.Active); err != nil {
		http.Error(w, "Failed to update RFID status", http.StatusInternalServerError)
		return
	}

	w.WriteHeader(http.StatusOK)
	json.NewEncoder(w).Encode(map[string]string{"message": "RFID status updated"})
}
