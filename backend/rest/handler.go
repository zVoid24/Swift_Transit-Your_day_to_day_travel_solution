package rest

import (
	"swift_transit/config"
	"swift_transit/rest/handlers/bus"
	"swift_transit/rest/handlers/route"
	"swift_transit/rest/handlers/ticket"
	"swift_transit/rest/handlers/user"
	"swift_transit/rest/middlewares"
)

type Handler struct {
	cnf           *config.Config
	mdlw          *middlewares.Handler
	userHandler   *user.Handler
	routeHandler  *route.Handler
	busHandler    *bus.Handler
	ticketHandler *ticket.Handler
}

func NewHandler(cnf *config.Config, mdlw *middlewares.Handler, userHandler *user.Handler, routeHandler *route.Handler, busHandler *bus.Handler, ticketHandler *ticket.Handler) *Handler {
	return &Handler{
		cnf:           cnf,
		mdlw:          mdlw,
		userHandler:   userHandler,
		routeHandler:  routeHandler,
		busHandler:    busHandler,
		ticketHandler: ticketHandler,
	}
}
