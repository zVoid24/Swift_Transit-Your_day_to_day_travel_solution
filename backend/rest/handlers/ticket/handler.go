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
	publicBaseURL     string
}

func NewHandler(svc Service, middlewareHandler *middlewares.Handler, mngr *middlewares.Manager, utilHandler *utils.Handler, publicBaseURL string) *Handler {
	return &Handler{
		svc:               svc,
		middlewareHandler: middlewareHandler,
		mngr:              mngr,
		utilHandler:       utilHandler,
		publicBaseURL:     publicBaseURL,
	}
}
