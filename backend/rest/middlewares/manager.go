package middlewares

import "net/http"

type Middleware func(http.Handler) http.Handler

type Manager struct {
	globalMiddlewares []Middleware
}

func (h *Handler) NewManager() *Manager {

	glbmw := make([]Middleware, 0)
	return &Manager{
		globalMiddlewares: glbmw,
	}

}

func (mngr *Manager) Use(middleWares ...Middleware) {
	mngr.globalMiddlewares = append(mngr.globalMiddlewares, middleWares...)
}

func (mngr *Manager) WrapMux(handler http.Handler) http.Handler {
	h := handler

	for _, middleware := range mngr.globalMiddlewares {
		h = middleware(h)
	}
	return h
}

func (mngr *Manager) With(handler http.Handler,middlewares ...Middleware) http.Handler {
	h := handler
	for _,middleware := range middlewares{
		h = middleware(h)
	}
	return h
}
