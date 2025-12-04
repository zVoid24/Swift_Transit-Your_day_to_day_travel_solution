package user

import (
	"context"
	"swift_transit/location"
	"swift_transit/rest/middlewares"
	"swift_transit/utils"

	"github.com/go-redis/redis/v8"
)

type Handler struct {
	svc               Service
	middlewareHandler *middlewares.Handler
	mngr              *middlewares.Manager
	utilHandler       *utils.Handler
	redis             *redis.Client
	ctx               context.Context
	hub               *location.Hub
}

func NewHandler(svc Service, middlewareHandler *middlewares.Handler, mngr *middlewares.Manager, utilHandler *utils.Handler, redis *redis.Client, ctx context.Context, hub *location.Hub) *Handler {
	return &Handler{
		svc:               svc,
		middlewareHandler: middlewareHandler,
		mngr:              mngr,
		utilHandler:       utilHandler,
		redis:             redis,
		ctx:               ctx,
		hub:               hub,
	}
}
