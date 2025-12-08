package rest

import (
	"swift_transit/config"
	"swift_transit/rest/handlers/admin"
	"swift_transit/rest/handlers/bus"
	"swift_transit/rest/handlers/bus_owner"
	"swift_transit/rest/handlers/route"
	"swift_transit/rest/handlers/ticket"
	"swift_transit/rest/handlers/transaction"
	"swift_transit/rest/handlers/user"
	"swift_transit/rest/middlewares"
)

type Handler struct {
	cnf                *config.Config
	mdlw               *middlewares.Handler
	userHandler        *user.Handler
	routeHandler       *route.Handler
	busHandler         *bus.Handler
	ticketHandler      *ticket.Handler
	transactionHandler *transaction.Handler
	busOwnerHandler    *bus_owner.Handler
	adminHandler       *admin.Handler
}

func NewHandler(cnf *config.Config, mdlw *middlewares.Handler, userHandler *user.Handler, routeHandler *route.Handler, busHandler *bus.Handler, ticketHandler *ticket.Handler, transactionHandler *transaction.Handler, busOwnerHandler *bus_owner.Handler, adminHandler *admin.Handler) *Handler {
	return &Handler{
		cnf:                cnf,
		mdlw:               mdlw,
		userHandler:        userHandler,
		routeHandler:       routeHandler,
		busHandler:         busHandler,
		ticketHandler:      ticketHandler,
		transactionHandler: transactionHandler,
		busOwnerHandler:    busOwnerHandler,
		adminHandler:       adminHandler,
	}
}
