package bus

import (
	"swift_transit/location" // Added import for location package
	"swift_transit/rest/middlewares"
	"swift_transit/utils"
)

type Handler struct {
	svc               Service
	middlewareHandler *middlewares.Handler
	mngr              *middlewares.Manager
	utilHandler       *utils.Handler
	hub               *location.Hub // Added Hub field
}

func NewHandler(svc Service, middlewareHandler *middlewares.Handler, mngr *middlewares.Manager, utilHandler *utils.Handler, hub *location.Hub) *Handler {
	return &Handler{
		svc:               svc,
		middlewareHandler: middlewareHandler,
		mngr:              mngr,
		utilHandler:       utilHandler,
		hub:               hub, // Initialized Hub field
	}
}
