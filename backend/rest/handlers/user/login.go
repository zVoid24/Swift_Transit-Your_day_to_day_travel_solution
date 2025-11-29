package user

import (
	"encoding/json"
	"net/http"
)

type LoginRequest struct {
	UserName string `json:"username"`
	Password string `json:"password"`
}

// LoginResponse represents JSON response
type LoginResponse struct {
	Message string      `json:"message"`
	JWT     string      `json:"jwt,omitempty"`
	User    interface{} `json:"user,omitempty"`
}

// Login handles user login
func (h *Handler) Login(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")

	// Decode JSON request
	var req LoginRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		w.WriteHeader(http.StatusBadRequest)
		json.NewEncoder(w).Encode(LoginResponse{Message: "Invalid JSON payload"})
		return
	}

	// Validate input
	if req.UserName == "" || req.Password == "" {
		w.WriteHeader(http.StatusBadRequest)
		json.NewEncoder(w).Encode(LoginResponse{Message: "Username and password required"})
		return
	}

	// Check credentials
	user, err := h.svc.Find(req.UserName, req.Password)
	if err != nil {
		w.WriteHeader(http.StatusUnauthorized)
		json.NewEncoder(w).Encode(LoginResponse{Message: "Invalid username or password"})
		return
	}

	// Success
	jwt, err := h.utilHandler.CreateJWT(user)
	if err != nil {
		h.utilHandler.SendError(w, LoginResponse{Message: "Failed to generate JWT"}, http.StatusBadRequest)
	}
	h.utilHandler.SendData(w, LoginResponse{
		Message: "Login successful",
		JWT:     jwt,
		User:    user,
	}, http.StatusOK)

}
