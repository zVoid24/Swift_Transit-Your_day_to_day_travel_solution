package ticket

import (
	"net/http"
)

func (h *Handler) PaymentCancel(w http.ResponseWriter, r *http.Request) {
	// We can log the cancellation here if needed
	// idStr := r.URL.Query().Get("id")

	h.utilHandler.SendError(w, map[string]string{
		"message": "Payment cancelled",
		"status":  "cancelled",
	}, http.StatusOK)
}
