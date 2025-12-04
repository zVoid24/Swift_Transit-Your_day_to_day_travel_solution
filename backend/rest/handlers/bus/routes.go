package bus

import "net/http"

func (h *Handler) RegisterRoutes(mux *http.ServeMux) {
	mux.Handle("GET /bus/find", h.mngr.With(http.HandlerFunc(h.GetBus)))
	mux.Handle("POST /bus/login", h.mngr.With(http.HandlerFunc(h.Login)))
	mux.Handle("POST /bus/validate", h.mngr.With(http.HandlerFunc(h.ValidateTicket)))
	mux.Handle("GET /ws/location", http.HandlerFunc(h.LocationSocket))
	mux.Handle("POST /bus/location", h.mngr.With(http.HandlerFunc(h.UpdateLocation)))
}
