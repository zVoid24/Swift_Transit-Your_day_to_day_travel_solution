package ticket

import (
	"encoding/json"
	"net/http"
)

type CreateOverTravelTicketRequest struct {
	OriginalTicketID int64  `json:"original_ticket_id"`
	CurrentStop      string `json:"current_stop"`
	PaymentCollected bool   `json:"payment_collected"`
}

func (h *Handler) CreateOverTravelTicket(w http.ResponseWriter, r *http.Request) {
	var req CreateOverTravelTicketRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		http.Error(w, "Invalid request body", http.StatusBadRequest)
		return
	}

	if req.OriginalTicketID == 0 || req.CurrentStop == "" {
		http.Error(w, "Missing required fields", http.StatusBadRequest)
		return
	}

	ticket, err := h.svc.CreateOverTravelTicket(req.OriginalTicketID, req.CurrentStop, req.PaymentCollected)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(ticket)
}
