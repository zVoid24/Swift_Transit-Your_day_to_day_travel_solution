package ticket

import "net/http"

func (h *Handler) RegisterRoutes(mux *http.ServeMux) {
	mux.Handle("POST /ticket/buy", h.mngr.With(http.HandlerFunc(h.BuyTicket), h.middlewareHandler.Authenticate))
	mux.Handle("/ticket/payment/success", h.mngr.With(http.HandlerFunc(h.PaymentSuccess)))
	mux.Handle("/ticket/payment/fail", h.mngr.With(http.HandlerFunc(h.PaymentFail)))
	mux.Handle("/ticket/payment/cancel", h.mngr.With(http.HandlerFunc(h.PaymentCancel)))
	mux.Handle("POST /ticket/payment/ipn", http.HandlerFunc(h.PaymentIPN)) // IPN usually comes from server, maybe no auth middleware needed or verify IP
	mux.Handle("GET /ticket/download", h.mngr.With(http.HandlerFunc(h.DownloadTicket)))
	mux.Handle("GET /ticket/status", h.mngr.With(http.HandlerFunc(h.GetTicketStatus)))
	mux.Handle("GET /ticket", h.mngr.With(http.HandlerFunc(h.GetTickets), h.middlewareHandler.Authenticate))
}
