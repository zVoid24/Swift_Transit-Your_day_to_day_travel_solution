package user

import "net/http"

func (h *Handler) Information(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")

	usr, err := h.svc.Info(r.Context())
	if err != nil {
		h.utilHandler.SendError(w, "Invalid user data", http.StatusBadRequest)
		return
	}
	h.utilHandler.SendData(w, usr, http.StatusOK)
}
