package user

import (
	"encoding/json"
	"fmt"
	"net/http"
	"swift_transit/domain"
	"swift_transit/utils"
	"time"
)

type RegisterRequest struct {
	Name      string  `json:"name"`
	Mobile    string  `json:"mobile"`
	NID       string  `json:"nid"`
	Email     string  `json:"email"`
	Password  string  `json:"password"`
	IsStudent bool    `json:"is_student"`
	Balance   float32 `json:"balance"`
}

type VerifySignupRequest struct {
	Email string `json:"email"`
	OTP   string `json:"otp"`
}

func (h *Handler) InitiateSignup(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "Invalid request method", http.StatusMethodNotAllowed)
		return
	}

	var req RegisterRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		h.utilHandler.SendError(w, "Invalid JSON payload", http.StatusBadRequest)
		return
	}

	// Basic validation (can be expanded)
	if req.Email == "" || req.Password == "" {
		h.utilHandler.SendError(w, map[string]string{"message": "Email and Password are required"}, http.StatusBadRequest)
		return
	}

	// Generate OTP
	otp := utils.GenerateOTP(6)

	// Store user data and OTP in Redis with expiration (e.g., 10 minutes)
	userData, err := json.Marshal(req)
	if err != nil {
		h.utilHandler.SendError(w, map[string]string{"message": "Failed to process user data"}, http.StatusInternalServerError)
		return
	}

	// Store OTP
	err = h.redis.Set(h.ctx, "signup_otp:"+req.Email, otp, 10*time.Minute).Err()
	if err != nil {
		h.utilHandler.SendError(w, map[string]string{"message": "Failed to store OTP"}, http.StatusInternalServerError)
		return
	}
	// Store User Data
	err = h.redis.Set(h.ctx, "signup_data:"+req.Email, userData, 10*time.Minute).Err()
	if err != nil {
		h.utilHandler.SendError(w, map[string]string{"message": "Failed to store user data"}, http.StatusInternalServerError)
		return
	}

	// Send Email
	// Send Email
	emailBody := utils.GetOTPEmailBody(otp)
	err = utils.SendEmail(req.Email, "Swift Transit Signup OTP", emailBody)
	if err != nil {
		h.utilHandler.SendError(w, map[string]string{"message": "Failed to send OTP"}, http.StatusInternalServerError)
		return
	}

	h.utilHandler.SendData(w, map[string]string{"message": "OTP sent to email. Please verify to complete signup."}, http.StatusOK)
}

func (h *Handler) VerifySignup(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "Invalid request method", http.StatusMethodNotAllowed)
		return
	}

	var req VerifySignupRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		h.utilHandler.SendError(w, map[string]string{"message": "Invalid JSON payload"}, http.StatusBadRequest)
		return
	}

	// Verify OTP
	storedOTP, err := h.redis.Get(h.ctx, "signup_otp:"+req.Email).Result()
	if err != nil {
		h.utilHandler.SendError(w, map[string]string{"message": "Invalid or expired OTP"}, http.StatusBadRequest)
		return
	}

	if storedOTP != req.OTP {
		h.utilHandler.SendError(w, map[string]string{"message": "Invalid OTP"}, http.StatusBadRequest)
		return
	}

	// Retrieve User Data
	storedUserData, err := h.redis.Get(h.ctx, "signup_data:"+req.Email).Result()
	if err != nil {
		h.utilHandler.SendError(w, map[string]string{"message": "Session expired, please signup again"}, http.StatusBadRequest)
		return
	}

	var userReq RegisterRequest
	if err := json.Unmarshal([]byte(storedUserData), &userReq); err != nil {
		h.utilHandler.SendError(w, map[string]string{"message": "Failed to process user data"}, http.StatusInternalServerError)
		return
	}

	// Create User in DB
	user := domain.User{
		Name:      userReq.Name,
		Mobile:    userReq.Mobile,
		NID:       userReq.NID,
		Email:     userReq.Email,
		Password:  userReq.Password,
		IsStudent: userReq.IsStudent,
		Balance:   userReq.Balance,
	}

	createdUser, err := h.svc.Create(user)
	if err != nil {
		h.utilHandler.SendError(w, map[string]string{"message": fmt.Sprintf("Failed to create user: %s", err.Error())}, http.StatusInternalServerError)
		return
	}

	// Cleanup Redis
	h.redis.Del(h.ctx, "signup_otp:"+req.Email)
	h.redis.Del(h.ctx, "signup_data:"+req.Email)

	resp := map[string]interface{}{
		"message":    "User created successfully",
		"id":         createdUser.Id,
		"name":       createdUser.Name,
		"mobile":     createdUser.Mobile,
		"nid":        createdUser.NID,
		"email":      createdUser.Email,
		"is_student": createdUser.IsStudent,
		"balance":    createdUser.Balance,
	}

	h.utilHandler.SendData(w, resp, http.StatusOK)
}
