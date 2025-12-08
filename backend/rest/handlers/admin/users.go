package admin

import (
	"encoding/json"
	"net/http"
	"strconv"
	"swift_transit/domain"
)

func (h *Handler) GetAllUsers(w http.ResponseWriter, r *http.Request) {
	// Get pagination parameters
	page, _ := strconv.Atoi(r.URL.Query().Get("page"))
	if page < 1 {
		page = 1
	}

	pageSize, _ := strconv.Atoi(r.URL.Query().Get("page_size"))
	if pageSize < 1 {
		pageSize = 20
	}

	users, total, err := h.svc.GetAllUsers(page, pageSize)
	if err != nil {
		h.utilHandler.SendError(w, err.Error(), http.StatusInternalServerError)
		return
	}

	h.utilHandler.SendData(w, map[string]interface{}{
		"users":       users,
		"total":       total,
		"page":        page,
		"page_size":   pageSize,
		"total_pages": (total + pageSize - 1) / pageSize,
	}, http.StatusOK)
}

func (h *Handler) GetUserByID(w http.ResponseWriter, r *http.Request) {
	idStr := r.PathValue("id")
	id, err := strconv.ParseInt(idStr, 10, 64)
	if err != nil {
		h.utilHandler.SendError(w, "Invalid user ID", http.StatusBadRequest)
		return
	}

	user, err := h.svc.GetUserByID(id)
	if err != nil {
		h.utilHandler.SendError(w, err.Error(), http.StatusNotFound)
		return
	}

	h.utilHandler.SendData(w, user, http.StatusOK)
}

func (h *Handler) UpdateUser(w http.ResponseWriter, r *http.Request) {
	idStr := r.PathValue("id")
	id, err := strconv.ParseInt(idStr, 10, 64)
	if err != nil {
		h.utilHandler.SendError(w, "Invalid user ID", http.StatusBadRequest)
		return
	}

	var user domain.User
	if err := json.NewDecoder(r.Body).Decode(&user); err != nil {
		h.utilHandler.SendError(w, "Invalid request body", http.StatusBadRequest)
		return
	}

	user.Id = id
	if err := h.svc.UpdateUser(user); err != nil {
		h.utilHandler.SendError(w, err.Error(), http.StatusInternalServerError)
		return
	}

	h.utilHandler.SendData(w, map[string]string{"message": "User updated successfully"}, http.StatusOK)
}

func (h *Handler) DeleteUser(w http.ResponseWriter, r *http.Request) {
	idStr := r.PathValue("id")
	id, err := strconv.ParseInt(idStr, 10, 64)
	if err != nil {
		h.utilHandler.SendError(w, "Invalid user ID", http.StatusBadRequest)
		return
	}

	if err := h.svc.DeleteUser(id); err != nil {
		h.utilHandler.SendError(w, err.Error(), http.StatusInternalServerError)
		return
	}

	h.utilHandler.SendData(w, map[string]string{"message": "User deleted successfully"}, http.StatusOK)
}
