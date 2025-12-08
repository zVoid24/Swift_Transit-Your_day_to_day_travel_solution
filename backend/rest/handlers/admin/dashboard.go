package admin

import (
	"net/http"
)

func (h *Handler) GetDashboardStats(w http.ResponseWriter, r *http.Request) {
	stats, err := h.svc.GetDashboardStats()
	if err != nil {
		h.utilHandler.SendError(w, err.Error(), http.StatusInternalServerError)
		return
	}
	h.utilHandler.SendData(w, stats, http.StatusOK)
}
