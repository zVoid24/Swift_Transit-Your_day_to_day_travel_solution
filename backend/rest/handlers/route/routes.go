package route

import "net/http"

func (h *Handler) RegisterRoutes(mux *http.ServeMux) {
	mux.Handle("POST /route", h.mngr.With(http.HandlerFunc(h.Create)))
	mux.Handle("GET /route/{id}", h.mngr.With(http.HandlerFunc(h.GetByID)))
}
