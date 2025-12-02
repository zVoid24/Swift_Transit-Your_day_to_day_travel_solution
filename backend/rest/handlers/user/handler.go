package user

import (
	"swift_transit/rest/middlewares"
	"swift_transit/utils"

	"github.com/go-redis/redis/v8"
)

type Handler struct {
	svc               Service
	middlewareHandler *middlewares.Handler
	mngr              *middlewares.Manager
	utilHandler       *utils.Handler
	redisClient       *redis.Client
}

func NewHandler(svc Service, middlewareHandler *middlewares.Handler, mngr *middlewares.Manager, utilHandler *utils.Handler, redisClient *redis.Client) *Handler {
	return &Handler{
		svc:               svc,
		middlewareHandler: middlewareHandler,
		mngr:              mngr,
		utilHandler:       utilHandler,
		redisClient:       redisClient,
	}
}
