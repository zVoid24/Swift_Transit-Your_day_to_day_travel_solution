package admin

import (
	"swift_transit/admin"
	"swift_transit/rest/middlewares"
	"swift_transit/utils"
)

type Handler struct {
	svc               admin.Service
	utilHandler       *utils.Handler
	middlewareHandler *middlewares.Handler
	mngr              *middlewares.Manager
}

func NewHandler(svc admin.Service, utilHandler *utils.Handler, middlewareHandler *middlewares.Handler, mngr *middlewares.Manager) *Handler {
	return &Handler{
		svc:               svc,
		utilHandler:       utilHandler,
		middlewareHandler: middlewareHandler,
		mngr:              mngr,
	}
}
