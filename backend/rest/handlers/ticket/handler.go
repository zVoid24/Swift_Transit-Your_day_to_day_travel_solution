package ticket

import (
	"swift_transit/rest/middlewares"
	"swift_transit/utils"
)

type Handler struct {
	svc               Service
	middlewareHandler *middlewares.Handler
	mngr              *middlewares.Manager
	utilHandler       *utils.Handler
}

func NewHandler(svc Service, middlewareHandler *middlewares.Handler, mngr *middlewares.Manager, utilHandler *utils.Handler) *Handler {
	return &Handler{
		svc:               svc,
		middlewareHandler: middlewareHandler,
		mngr:              mngr,
		utilHandler:       utilHandler,
	}
}
