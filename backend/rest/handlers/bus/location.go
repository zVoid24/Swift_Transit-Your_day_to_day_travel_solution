package bus

import (
	"encoding/json"
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

func (h *Handler) UpdateLocation(w http.ResponseWriter, r *http.Request) {
	var update location.LocationUpdate
	if err := json.NewDecoder(r.Body).Decode(&update); err != nil {
		h.utilHandler.SendError(w, "Invalid request body", http.StatusBadRequest)
		return
	}

	// Basic validation
	if update.RouteID == 0 || update.BusID == 0 {
		h.utilHandler.SendError(w, "route_id and bus_id are required", http.StatusBadRequest)
		return
	}

	h.hub.BroadcastLocation(update)
	h.utilHandler.SendData(w, "Location updated", http.StatusOK)
}
