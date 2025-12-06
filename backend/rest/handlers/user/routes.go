package user

import (
	"net/http"
)

func (h *Handler) RegisterRoutes(mux *http.ServeMux) {
	// Signup Flow
	mux.Handle("POST /user", h.mngr.With(http.HandlerFunc(h.InitiateSignup)))
	mux.Handle("POST /user/verify", h.mngr.With(http.HandlerFunc(h.VerifySignup)))

	// Login
	mux.Handle("POST /auth/login", h.mngr.With(http.HandlerFunc(h.Login)))

	// Forgot Password Flow
	mux.Handle("POST /auth/forgot-password", h.mngr.With(http.HandlerFunc(h.InitiateForgotPassword)))
	mux.Handle("POST /auth/verify-otp", h.mngr.With(http.HandlerFunc(h.VerifyForgotPasswordOTP)))
	mux.Handle("POST /auth/reset-password", h.mngr.With(http.HandlerFunc(h.ResetPassword)))

	// User Info
	mux.Handle("GET /user", h.mngr.With(http.HandlerFunc(h.Information), h.middlewareHandler.Authenticate))
	mux.Handle("PUT /user", h.mngr.With(http.HandlerFunc(h.UpdateProfile), h.middlewareHandler.Authenticate))
	mux.Handle("POST /auth/change-password", h.mngr.With(http.HandlerFunc(h.ChangePassword), h.middlewareHandler.Authenticate))
	mux.Handle("GET /user/rfid", h.mngr.With(http.HandlerFunc(h.GetRFIDStatus), h.middlewareHandler.Authenticate))
	mux.Handle("POST /user/rfid/toggle", h.mngr.With(http.HandlerFunc(h.ToggleRFIDStatus), h.middlewareHandler.Authenticate))
}
