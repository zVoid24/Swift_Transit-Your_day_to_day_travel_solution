package user

import (
	"net/http"
)

func (h *Handler) RegisterRoutes(mux *http.ServeMux) {
	mux.Handle("POST /user", h.mngr.With(http.HandlerFunc(h.Register)))
	mux.Handle("POST /auth/login", h.mngr.With(http.HandlerFunc(h.Login)))
	mux.Handle("GET /user", h.mngr.With(http.HandlerFunc(h.Information), h.middlewareHandler.Authenticate))
}
