package route

import (
	"net/http"
	"strconv"
)

func (h *Handler) GetByID(w http.ResponseWriter, r *http.Request) {
	idStr := r.PathValue("id")
	id, err := strconv.ParseInt(idStr, 10, 64)
	if err != nil {
		h.utilHandler.SendError(w, "Invalid route ID", http.StatusBadRequest)
		return
	}

	route, err := h.svc.FindByID(id)
	if err != nil {
		h.utilHandler.SendError(w, err.Error(), http.StatusNotFound)
		return
	}

	h.utilHandler.SendData(w, route, http.StatusOK)
}
