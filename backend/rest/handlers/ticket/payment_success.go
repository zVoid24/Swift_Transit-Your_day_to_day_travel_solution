package ticket

import (
	"fmt"
	"net/http"
	"strconv"
)

func (h *Handler) PaymentSuccess(w http.ResponseWriter, r *http.Request) {
	idStr := r.URL.Query().Get("id")
	if idStr == "" {
		h.utilHandler.SendError(w, map[string]string{"error": "missing id parameter"}, http.StatusBadRequest)
		return
	}

	id, err := strconv.Atoi(idStr)
	if err != nil {
		h.utilHandler.SendError(w, map[string]string{"error": "invalid id parameter"}, http.StatusBadRequest)
		return
	}

	err = h.svc.UpdatePaymentStatus(int64(id))
	if err != nil {
		h.utilHandler.SendError(w, map[string]string{"error": err.Error()}, http.StatusInternalServerError)
		return
	}

	h.utilHandler.SendData(w, map[string]string{
		"message":      "Payment successful",
		"download_url": fmt.Sprintf("http://localhost:8080/ticket/download?id=%d", id),
	}, http.StatusOK)
}
