package bus

import "net/http"

func (h *Handler) RegisterRoutes(mux *http.ServeMux) {
	mux.Handle("POST /bus/get", h.mngr.With(http.HandlerFunc(h.GetBus)))

}
