package bus

import (
	"encoding/json"
	"net/http"
)

type GetBusRequest struct {
	StartDestination string `json:"start_destination"`
	EndDestination   string `json:"end_destination"`
}

func (h *Handler) GetBus(w http.ResponseWriter, r *http.Request) {
	var req GetBusRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		h.utilHandler.SendError(w, "Invalid request body", http.StatusBadRequest)
		return
	}

	if req.StartDestination == "" || req.EndDestination == "" {
		h.utilHandler.SendError(w, "start_destination and end_destination are required", http.StatusBadRequest)
		return
	}

	buses, err := h.svc.FindBus(req.StartDestination, req.EndDestination)
	if err != nil {
		h.utilHandler.SendError(w, "Failed to find bus", http.StatusInternalServerError)
		return
	}

	h.utilHandler.SendData(w, buses, http.StatusOK)
}
