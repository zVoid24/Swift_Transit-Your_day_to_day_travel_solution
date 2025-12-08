package bus_owner

import "net/http"

func (h *Handler) RegisterRoutes(mux *http.ServeMux) {
	mux.Handle("POST /bus-owner/auth/register", http.HandlerFunc(h.Register))
	mux.Handle("POST /bus-owner/auth/login", http.HandlerFunc(h.Login))
	// Add middleware for protected routes
	mux.Handle("POST /bus-owner/buses", h.mngr.With(http.HandlerFunc(h.RegisterBus), h.middlewareHandler.Authenticate)) // Need auth middleware for bus owner
	mux.Handle("GET /bus-owner/buses", h.mngr.With(http.HandlerFunc(h.GetBuses), h.middlewareHandler.Authenticate))
	mux.Handle("GET /bus-owner/analytics", h.mngr.With(http.HandlerFunc(h.GetAnalytics), h.middlewareHandler.Authenticate))
	mux.Handle("GET /bus-owner/analytics/per-bus", h.mngr.With(http.HandlerFunc(h.GetPerBusAnalytics), h.middlewareHandler.Authenticate))
	mux.Handle("GET /bus-owner/routes", h.mngr.With(http.HandlerFunc(h.GetRoutes), h.middlewareHandler.Authenticate))
}
