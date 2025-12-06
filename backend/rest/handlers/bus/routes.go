package bus

import "net/http"

func (h *Handler) RegisterRoutes(mux *http.ServeMux) {
	mux.Handle("GET /bus/find", h.mngr.With(http.HandlerFunc(h.GetBus)))
	mux.Handle("POST /bus/find", h.mngr.With(http.HandlerFunc(h.GetBus)))
	mux.Handle("POST /bus/get", h.mngr.With(http.HandlerFunc(h.GetBus)))
	mux.Handle("POST /bus/auth/login", h.mngr.With(http.HandlerFunc(h.Login)))
	mux.Handle("POST /bus/auth/register", h.mngr.With(http.HandlerFunc(h.Register)))
	mux.Handle("POST /bus/validate", h.mngr.With(http.HandlerFunc(h.ValidateTicket), h.middlewareHandler.Authenticate))
	mux.Handle("POST /bus/check-ticket", h.mngr.With(http.HandlerFunc(h.CheckTicket), h.middlewareHandler.Authenticate))
	mux.Handle("GET /ws/location", http.HandlerFunc(h.LocationSocket))
	mux.Handle("POST /bus/location", h.mngr.With(http.HandlerFunc(h.UpdateLocation), h.middlewareHandler.Authenticate))
}
