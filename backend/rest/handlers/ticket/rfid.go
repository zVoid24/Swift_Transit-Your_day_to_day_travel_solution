package ticket

import (
	"encoding/json"
	"net/http"
	"swift_transit/ticket"
)

func (h *Handler) ProcessRFIDPayment(w http.ResponseWriter, r *http.Request) {
	var req ticket.RFIDPaymentRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		http.Error(w, "Invalid request body", http.StatusBadRequest)
		return
	}

	resp, err := h.svc.ProcessRFIDPayment(req)
	if err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(resp)
}
