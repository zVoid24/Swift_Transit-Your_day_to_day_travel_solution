package ticket

import (
	"net/http"
)

func (h *Handler) GetTicketStatus(w http.ResponseWriter, r *http.Request) {
	trackingID := r.URL.Query().Get("tracking_id")
	if trackingID == "" {
		h.utilHandler.SendError(w, "tracking_id is required", http.StatusBadRequest)
		return
	}

	res, err := h.svc.GetTicketStatus(trackingID)
	if err != nil {
		h.utilHandler.SendError(w, err.Error(), http.StatusNotFound)
		return
	}

	h.utilHandler.SendData(w, res, http.StatusOK)
}
