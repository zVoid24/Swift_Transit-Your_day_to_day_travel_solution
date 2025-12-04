package bus

import (
	"net/http"
	"strconv"
	"swift_transit/location"
)

func (h *Handler) LocationSocket(w http.ResponseWriter, r *http.Request) {
	// Bus connects to this endpoint to send location updates
	// We expect route_id in query params
	routeIDStr := r.URL.Query().Get("route_id")
	if routeIDStr == "" {
		h.utilHandler.SendError(w, "route_id is required", http.StatusBadRequest)
		return
	}

	routeID, err := strconv.ParseInt(routeIDStr, 10, 64)
	if err != nil {
		h.utilHandler.SendError(w, "invalid route_id", http.StatusBadRequest)
		return
	}

	// Upgrade to WebSocket
	location.ServeWs(h.hub, w, r, routeID)
}
