package bus

import (
	"encoding/json"
	"net/http"
	"swift_transit/ticket"
)

func (h *Handler) CheckTicket(w http.ResponseWriter, r *http.Request) {
	var req ticket.CheckTicketRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		http.Error(w, "Invalid request body", http.StatusBadRequest)
		return
	}

	// Basic validation
	if req.QRCode == "" || req.CurrentStoppage.Name == "" {
		h.utilHandler.SendError(w, "Missing required fields", http.StatusBadRequest)
		return
	}

	busData, err := h.BusFromContext(r)
	if err != nil {
		h.utilHandler.SendError(w, "Unauthorized", http.StatusUnauthorized)
		return
	}
	req.RouteID = busData.RouteId

	result, err := h.svc.CheckTicket(req)
	if err != nil {
		// Return JSON error even for bad requests so frontend can parse "message"
		h.utilHandler.SendError(w, err.Error(), http.StatusBadRequest)
		return
	}

	h.utilHandler.SendData(w, result, http.StatusOK)
}
