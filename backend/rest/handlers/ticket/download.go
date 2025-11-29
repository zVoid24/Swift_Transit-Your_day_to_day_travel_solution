package ticket

import (
	"fmt"
	"net/http"
	"strconv"
)

func (h *Handler) DownloadTicket(w http.ResponseWriter, r *http.Request) {
	idStr := r.URL.Query().Get("id")
	if idStr == "" {
		h.utilHandler.SendError(w, "missing id parameter", http.StatusBadRequest)
		return
	}

	id, err := strconv.Atoi(idStr)
	if err != nil {
		h.utilHandler.SendError(w, "invalid id parameter", http.StatusBadRequest)
		return
	}

	pdfBytes, err := h.svc.DownloadTicket(int64(id))
	if err != nil {
		h.utilHandler.SendError(w, err.Error(), http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/pdf")
	w.Header().Set("Content-Disposition", fmt.Sprintf("attachment; filename=ticket-%d.pdf", id))
	w.WriteHeader(http.StatusOK)
	w.Write(pdfBytes)
}
