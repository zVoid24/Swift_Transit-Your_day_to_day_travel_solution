package ticket

import (
	"net/http"
	"strconv"
)

func (h *Handler) GetTickets(w http.ResponseWriter, r *http.Request) {
	// Extract user ID from context
	userData := h.utilHandler.GetUserFromContext(r.Context())
	if userData == nil {
		h.utilHandler.SendError(w, "Unauthorized", http.StatusUnauthorized)
		return
	}

	var userId int64
	switch v := userData.(type) {
	case float64:
		userId = int64(v)
	case map[string]interface{}:
		if id, ok := v["id"].(float64); ok {
			userId = int64(id)
		}
	}

	if userId == 0 {
		h.utilHandler.SendError(w, "Invalid user data in token", http.StatusUnauthorized)
		return
	}

	page := 1
	limit := 10

	if p := r.URL.Query().Get("page"); p != "" {
		if parsed, err := strconv.Atoi(p); err == nil && parsed > 0 {
			page = parsed
		}
	}

	if l := r.URL.Query().Get("limit"); l != "" {
		if parsed, err := strconv.Atoi(l); err == nil && parsed > 0 {
			limit = parsed
		}
	}

	offset := (page - 1) * limit

	tickets, total, err := h.svc.GetByUserID(userId, limit, offset)
	if err != nil {
		h.utilHandler.SendError(w, "Failed to fetch tickets", http.StatusInternalServerError)
		return
	}

	h.utilHandler.SendData(w, map[string]any{
		"data":  tickets,
		"page":  page,
		"limit": limit,
		"total": total,
	}, http.StatusOK)
}
