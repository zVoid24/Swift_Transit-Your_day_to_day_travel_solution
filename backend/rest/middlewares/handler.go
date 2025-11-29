package middlewares

import "swift_transit/utils"

type Handler struct {
	utilHandler *utils.Handler
}

func NewHandler(utilHandler *utils.Handler) *Handler {
	return &Handler{
		utilHandler: utilHandler,
	}
}