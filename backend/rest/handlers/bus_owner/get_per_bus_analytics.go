package bus_owner

import "net/http"

func (h *Handler) GetPerBusAnalytics(w http.ResponseWriter, r *http.Request) {
	ownerID := h.utilHandler.GetUserIDFromContext(r.Context())
	if ownerID == 0 {
		h.utilHandler.SendError(w, "Unauthorized: Invalid user ID", http.StatusUnauthorized)
		return
	}

	analytics, err := h.svc.GetPerBusAnalytics(ownerID)
	if err != nil {
		h.utilHandler.SendError(w, err.Error(), http.StatusInternalServerError)
		return
	}

	h.utilHandler.SendData(w, analytics, http.StatusOK)
}
