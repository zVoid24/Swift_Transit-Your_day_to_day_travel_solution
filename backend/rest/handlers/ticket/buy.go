package ticket

import (
	"encoding/json"
	"net/http"
	"swift_transit/ticket"
)

func (h *Handler) BuyTicket(w http.ResponseWriter, r *http.Request) {
	var req ticket.BuyTicketRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		h.utilHandler.SendError(w, "Invalid request body", http.StatusBadRequest)
		return
	}

	// Basic validation
	if req.RouteId == 0 {
		h.utilHandler.SendError(w, "Invalid request parameters", http.StatusBadRequest)
		return
	}

	// Extract user ID from context
	userData := h.utilHandler.GetUserFromContext(r.Context())
	if userData == nil {
		h.utilHandler.SendError(w, "Unauthorized", http.StatusUnauthorized)
		return
	}

	// Assuming userData is float64 (from JSON unmarshal of JWT claims) or string depending on how it was stored.
	// We need to be careful here. Let's assume it's stored as float64 by default JSON unmarshal if it's a number.
	// Or if it was stored as a struct/map.
	// Let's try to cast to map[string]interface{} first if it was a struct, or float64 if it was just an ID.
	// Based on typical JWT implementations, if "data" was just an ID, it might be float64.
	// If "data" was a struct, it's a map.
	// Let's assume it's a map containing "id" or similar, OR just the ID.
	// Looking at create_jwt.go, it takes `data any`.
	// I'll assume for now it's a map[string]interface{} with "id" or similar, OR I'll try to cast to float64.

	// SAFE APPROACH: Check type
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
	req.UserId = userId

	resp, err := h.svc.BuyTicket(req)
	if err != nil {
		h.utilHandler.SendError(w, err.Error(), http.StatusInternalServerError)
		return
	}

	h.utilHandler.SendData(w, resp, http.StatusOK)
}
