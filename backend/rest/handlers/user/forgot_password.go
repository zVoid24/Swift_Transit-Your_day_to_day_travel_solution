package user

import (
	"encoding/json"
	"net/http"
	"swift_transit/utils"
	"time"

	"github.com/google/uuid"
)

type ForgotPasswordRequest struct {
	Email string `json:"email"`
}

type VerifyOTPRequest struct {
	Email string `json:"email"`
	OTP   string `json:"otp"`
}

type ResetPasswordRequest struct {
	Token       string `json:"token"`
	NewPassword string `json:"new_password"`
}

func (h *Handler) InitiateForgotPassword(w http.ResponseWriter, r *http.Request) {
	var req ForgotPasswordRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		h.utilHandler.SendError(w, "Invalid JSON payload", http.StatusBadRequest)
		return
	}

	// Check if user exists
	_, err := h.svc.FindByEmail(req.Email)
	if err != nil {
		// Don't reveal if user exists or not for security, but for now let's just say sent
		// Or if we want to be strict:
		h.utilHandler.SendError(w, map[string]string{"message": "User not found"}, http.StatusNotFound)
		return
	}

	otp := utils.GenerateOTP(6)
	err = h.redis.Set(h.ctx, "forgot_otp:"+req.Email, otp, 5*time.Minute).Err()
	if err != nil {
		h.utilHandler.SendError(w, map[string]string{"message": "Failed to generate OTP"}, http.StatusInternalServerError)
		return
	}

	// Send Email
	emailBody := utils.GetOTPEmailBody(otp)
	err = utils.SendEmail(req.Email, "Swift Transit Password Reset OTP", emailBody)
	if err != nil {
		h.utilHandler.SendError(w, map[string]string{"message": "Failed to send OTP"}, http.StatusInternalServerError)
		return
	}

	h.utilHandler.SendData(w, map[string]string{"message": "OTP sent to email"}, http.StatusOK)
}

func (h *Handler) VerifyForgotPasswordOTP(w http.ResponseWriter, r *http.Request) {
	var req VerifyOTPRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		h.utilHandler.SendError(w, map[string]string{"message": "Invalid JSON payload"}, http.StatusBadRequest)
		return
	}

	storedOTP, err := h.redis.Get(h.ctx, "forgot_otp:"+req.Email).Result()
	if err != nil || storedOTP != req.OTP {
		h.utilHandler.SendError(w, map[string]string{"message": "Invalid or expired OTP"}, http.StatusBadRequest)
		return
	}

	// OTP is valid, generate a reset token
	resetToken := uuid.New().String()
	err = h.redis.Set(h.ctx, "reset_token:"+resetToken, req.Email, 15*time.Minute).Err()
	if err != nil {
		h.utilHandler.SendError(w, map[string]string{"message": "Failed to generate reset token"}, http.StatusInternalServerError)
		return
	}

	// Clean up OTP
	h.redis.Del(h.ctx, "forgot_otp:"+req.Email)

	h.utilHandler.SendData(w, map[string]interface{}{"message": "OTP verified", "reset_token": resetToken}, http.StatusOK)
}

func (h *Handler) ResetPassword(w http.ResponseWriter, r *http.Request) {
	var req ResetPasswordRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		h.utilHandler.SendError(w, map[string]string{"message": "Invalid JSON payload"}, http.StatusBadRequest)
		return
	}

	email, err := h.redis.Get(h.ctx, "reset_token:"+req.Token).Result()
	if err != nil {
		h.utilHandler.SendError(w, map[string]string{"message": "Invalid or expired reset token"}, http.StatusBadRequest)
		return
	}

	err = h.svc.UpdatePassword(email, req.NewPassword)
	if err != nil {
		h.utilHandler.SendError(w, map[string]string{"message": "Failed to update password"}, http.StatusInternalServerError)
		return
	}

	// Cleanup Token
	h.redis.Del(h.ctx, "reset_token:"+req.Token)

	h.utilHandler.SendData(w, map[string]string{"message": "Password updated successfully"}, http.StatusOK)
}
