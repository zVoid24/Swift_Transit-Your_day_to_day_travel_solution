package bus

import (
	"fmt"
	"strconv"
	"swift_transit/location" // Added import for location package
	"swift_transit/rest/middlewares"
	"swift_transit/ticket"
	"swift_transit/utils"
)

type BusAuthData struct {
	Id                 int64          `json:"id"`
	RegistrationNumber string         `json:"registration_number"`
	RouteId            int64          `json:"route_id"`
	Variant            string         `json:"variant"`
	Variants           []RouteVariant `json:"variants,omitempty"`
}

type RouteVariant struct {
	Variant string `json:"variant"`
	RouteId int64  `json:"route_id"`
}

type AuthResponse struct {
	Token string      `json:"token"`
	Bus   BusAuthData `json:"bus"`
}

type Handler struct {
	svc               Service
	ticketService     ticket.Service
	middlewareHandler *middlewares.Handler
	mngr              *middlewares.Manager
	utilHandler       *utils.Handler
	hub               *location.Hub // Added Hub field
}

func NewHandler(svc Service, ticketService ticket.Service, middlewareHandler *middlewares.Handler, mngr *middlewares.Manager, utilHandler *utils.Handler, hub *location.Hub) *Handler {
	return &Handler{
		svc:               svc,
		ticketService:     ticketService,
		middlewareHandler: middlewareHandler,
		mngr:              mngr,
		utilHandler:       utilHandler,
		hub:               hub, // Initialized Hub field
	}
}

func (h *Handler) busFromContext(r *http.Request) (*BusAuthData, error) {
	raw := h.utilHandler.GetUserFromContext(r.Context())
	if raw == nil {
		return nil, fmt.Errorf("missing auth context")
	}

	data, ok := raw.(map[string]any)
	if !ok {
		return nil, fmt.Errorf("invalid auth context")
	}

	getInt64 := func(val any) int64 {
		switch v := val.(type) {
		case float64:
			return int64(v)
		case int64:
			return v
		case int:
			return int64(v)
		case string:
			if parsed, err := strconv.ParseInt(v, 10, 64); err == nil {
				return parsed
			}
		}
		return 0
	}

	bus := &BusAuthData{}
	if id, ok := data["id"]; ok {
		bus.Id = getInt64(id)
	}
	if reg, ok := data["registration_number"].(string); ok {
		bus.RegistrationNumber = reg
	}
	if routeID, ok := data["route_id"]; ok {
		bus.RouteId = getInt64(routeID)
	}
	if variant, ok := data["variant"].(string); ok {
		bus.Variant = variant
	}

	return bus, nil
}
