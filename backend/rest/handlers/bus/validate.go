package bus

import (
	"encoding/json"
	"net/http"
)

type ValidateTicketRequest struct {
	TicketID int64 `json:"ticket_id"`
	RouteID  int64 `json:"route_id"`
}

func (h *Handler) ValidateTicket(w http.ResponseWriter, r *http.Request) {
	var req ValidateTicketRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		h.utilHandler.SendError(w, "Invalid request body", http.StatusBadRequest)
		return
	}

	err := h.svc.ValidateTicket(req.TicketID, req.RouteID)
	if err != nil {
		h.utilHandler.SendError(w, "Validation failed", http.StatusBadRequest)
		return
	}

	h.utilHandler.SendData(w, "Ticket validated successfully", http.StatusOK)
}
