package user

import (
	"encoding/json"
	"fmt"
	"net/http"
	"swift_transit/domain"
)

type RegisterRequest struct {
	Name      string  `json:"name"`
	UserName  string  `json:"username"`
	Email     string  `json:"email"`
	Password  string  `json:"password"`
	IsStudent bool    `json:"is_student"`
	Balance   float32 `json:"balance"`
}

func (h *Handler) Register(w http.ResponseWriter, r *http.Request) {
	// Only allow POST requests
	if r.Method != http.MethodPost {
		http.Error(w, "Invalid request method", http.StatusMethodNotAllowed)
		return
	}

	// Decode the JSON request body into RegisterRequest struct
	var req RegisterRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		h.utilHandler.SendError(w, "Invalid JSON payload", http.StatusBadRequest)
		return
	}

	// Create the user struct
	user := domain.User{
		Name:      req.Name,
		UserName:  req.UserName,
		Email:     req.Email,
		Password:  req.Password,
		IsStudent: req.IsStudent,
		Balance:   req.Balance,
	}

	// Call the Create method from the UserRepo to create the user
	createdUser, err := h.svc.Create(user) // Assume userRepo is a global or injected dependency
	if err != nil {
		http.Error(w, fmt.Sprintf("Failed to create user: %s", err.Error()), http.StatusInternalServerError)
		return
	}

	// Create the response payload excluding the password
	resp := map[string]interface{}{
		"id":         createdUser.Id,
		"name":       createdUser.Name,
		"username":   createdUser.UserName,
		"email":      createdUser.Email,
		"is_student": createdUser.IsStudent,
		"balance":    createdUser.Balance,
	}

	// Set response header to JSON
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)

	// Encode the response payload into JSON and send it back
	if err := json.NewEncoder(w).Encode(resp); err != nil {
		http.Error(w, fmt.Sprintf("Error encoding response: %s", err.Error()), http.StatusInternalServerError)
	}
}
