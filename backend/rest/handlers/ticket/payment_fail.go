package ticket

import (
	"net/http"
)

func (h *Handler) PaymentFail(w http.ResponseWriter, r *http.Request) {
	// We can log the failure here if needed
	// idStr := r.URL.Query().Get("id")

	h.utilHandler.SendError(w, map[string]string{
		"message": "Payment failed",
		"status":  "failed",
	}, http.StatusOK) // Return 200 so frontend can handle it gracefully, or 400? Usually 200 with status failed is easier for redirection handling.
}
