package ticket

import "net/http"

func (h *Handler) RegisterRoutes(mux *http.ServeMux) {
	mux.Handle("POST /ticket/buy", h.mngr.With(http.HandlerFunc(h.BuyTicket), h.middlewareHandler.Authenticate))
	mux.Handle("POST /ticket/payment/success", h.mngr.With(http.HandlerFunc(h.PaymentSuccess)))
	mux.Handle("GET /ticket/download", h.mngr.With(http.HandlerFunc(h.DownloadTicket)))
	mux.Handle("GET /ticket/status", h.mngr.With(http.HandlerFunc(h.GetTicketStatus)))
}
