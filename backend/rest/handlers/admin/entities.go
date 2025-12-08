package admin

import (
	"encoding/json"
	"net/http"
	"strconv"
	"swift_transit/domain"
)

// Bus Owners
func (h *Handler) GetAllBusOwners(w http.ResponseWriter, r *http.Request) {
	page, _ := strconv.Atoi(r.URL.Query().Get("page"))
	if page < 1 {
		page = 1
	}
	pageSize, _ := strconv.Atoi(r.URL.Query().Get("page_size"))
	if pageSize < 1 {
		pageSize = 20
	}

	owners, total, err := h.svc.GetAllBusOwners(page, pageSize)
	if err != nil {
		h.utilHandler.SendError(w, err.Error(), http.StatusInternalServerError)
		return
	}

	h.utilHandler.SendData(w, map[string]interface{}{
		"bus_owners":  owners,
		"total":       total,
		"page":        page,
		"page_size":   pageSize,
		"total_pages": (total + pageSize - 1) / pageSize,
	}, http.StatusOK)
}

func (h *Handler) CreateBusOwner(w http.ResponseWriter, r *http.Request) {
	var owner domain.BusOwner
	if err := json.NewDecoder(r.Body).Decode(&owner); err != nil {
		h.utilHandler.SendError(w, "Invalid request body", http.StatusBadRequest)
		return
	}

	if err := h.svc.CreateBusOwner(owner); err != nil {
		h.utilHandler.SendError(w, err.Error(), http.StatusInternalServerError)
		return
	}

	h.utilHandler.SendData(w, map[string]string{"message": "Bus owner created successfully"}, http.StatusCreated)
}

func (h *Handler) UpdateBusOwner(w http.ResponseWriter, r *http.Request) {
	idStr := r.PathValue("id")
	id, err := strconv.ParseInt(idStr, 10, 64)
	if err != nil {
		h.utilHandler.SendError(w, "Invalid ID", http.StatusBadRequest)
		return
	}

	var owner domain.BusOwner
	if err := json.NewDecoder(r.Body).Decode(&owner); err != nil {
		h.utilHandler.SendError(w, "Invalid request body", http.StatusBadRequest)
		return
	}

	owner.Id = id
	if err := h.svc.UpdateBusOwner(owner); err != nil {
		h.utilHandler.SendError(w, err.Error(), http.StatusInternalServerError)
		return
	}

	h.utilHandler.SendData(w, map[string]string{"message": "Bus owner updated successfully"}, http.StatusOK)
}

func (h *Handler) DeleteBusOwner(w http.ResponseWriter, r *http.Request) {
	idStr := r.PathValue("id")
	id, err := strconv.ParseInt(idStr, 10, 64)
	if err != nil {
		h.utilHandler.SendError(w, "Invalid ID", http.StatusBadRequest)
		return
	}

	if err := h.svc.DeleteBusOwner(id); err != nil {
		h.utilHandler.SendError(w, err.Error(), http.StatusInternalServerError)
		return
	}

	h.utilHandler.SendData(w, map[string]string{"message": "Bus owner deleted successfully"}, http.StatusOK)
}

// Buses
func (h *Handler) GetAllBuses(w http.ResponseWriter, r *http.Request) {
	page, _ := strconv.Atoi(r.URL.Query().Get("page"))
	if page < 1 {
		page = 1
	}
	pageSize, _ := strconv.Atoi(r.URL.Query().Get("page_size"))
	if pageSize < 1 {
		pageSize = 20
	}

	buses, total, err := h.svc.GetAllBuses(page, pageSize)
	if err != nil {
		h.utilHandler.SendError(w, err.Error(), http.StatusInternalServerError)
		return
	}

	h.utilHandler.SendData(w, map[string]interface{}{
		"buses":       buses,
		"total":       total,
		"page":        page,
		"page_size":   pageSize,
		"total_pages": (total + pageSize - 1) / pageSize,
	}, http.StatusOK)
}

func (h *Handler) UpdateBus(w http.ResponseWriter, r *http.Request) {
	idStr := r.PathValue("id")
	id, err := strconv.ParseInt(idStr, 10, 64)
	if err != nil {
		h.utilHandler.SendError(w, "Invalid ID", http.StatusBadRequest)
		return
	}

	var bus domain.BusCredential
	if err := json.NewDecoder(r.Body).Decode(&bus); err != nil {
		h.utilHandler.SendError(w, "Invalid request body", http.StatusBadRequest)
		return
	}

	bus.Id = id
	if err := h.svc.UpdateBus(bus); err != nil {
		h.utilHandler.SendError(w, err.Error(), http.StatusInternalServerError)
		return
	}

	h.utilHandler.SendData(w, map[string]string{"message": "Bus updated successfully"}, http.StatusOK)
}

func (h *Handler) DeleteBus(w http.ResponseWriter, r *http.Request) {
	idStr := r.PathValue("id")
	id, err := strconv.ParseInt(idStr, 10, 64)
	if err != nil {
		h.utilHandler.SendError(w, "Invalid ID", http.StatusBadRequest)
		return
	}

	if err := h.svc.DeleteBus(id); err != nil {
		h.utilHandler.SendError(w, err.Error(), http.StatusInternalServerError)
		return
	}

	h.utilHandler.SendData(w, map[string]string{"message": "Bus deleted successfully"}, http.StatusOK)
}

// Routes
func (h *Handler) GetAllRoutes(w http.ResponseWriter, r *http.Request) {
	page, _ := strconv.Atoi(r.URL.Query().Get("page"))
	if page < 1 {
		page = 1
	}
	pageSize, _ := strconv.Atoi(r.URL.Query().Get("page_size"))
	if pageSize < 1 {
		pageSize = 20
	}

	routes, total, err := h.svc.GetAllRoutes(page, pageSize)
	if err != nil {
		h.utilHandler.SendError(w, err.Error(), http.StatusInternalServerError)
		return
	}

	h.utilHandler.SendData(w, map[string]interface{}{
		"routes":      routes,
		"total":       total,
		"page":        page,
		"page_size":   pageSize,
		"total_pages": (total + pageSize - 1) / pageSize,
	}, http.StatusOK)
}

func (h *Handler) DeleteRoute(w http.ResponseWriter, r *http.Request) {
	idStr := r.PathValue("id")
	id, err := strconv.ParseInt(idStr, 10, 64)
	if err != nil {
		h.utilHandler.SendError(w, "Invalid ID", http.StatusBadRequest)
		return
	}

	if err := h.svc.DeleteRoute(id); err != nil {
		h.utilHandler.SendError(w, err.Error(), http.StatusInternalServerError)
		return
	}

	h.utilHandler.SendData(w, map[string]string{"message": "Route deleted successfully"}, http.StatusOK)
}

// Tickets
func (h *Handler) GetAllTickets(w http.ResponseWriter, r *http.Request) {
	page, _ := strconv.Atoi(r.URL.Query().Get("page"))
	if page < 1 {
		page = 1
	}
	pageSize, _ := strconv.Atoi(r.URL.Query().Get("page_size"))
	if pageSize < 1 {
		pageSize = 20
	}

	tickets, total, err := h.svc.GetAllTickets(page, pageSize)
	if err != nil {
		h.utilHandler.SendError(w, err.Error(), http.StatusInternalServerError)
		return
	}

	h.utilHandler.SendData(w, map[string]interface{}{
		"tickets":     tickets,
		"total":       total,
		"page":        page,
		"page_size":   pageSize,
		"total_pages": (total + pageSize - 1) / pageSize,
	}, http.StatusOK)
}

// Transactions
func (h *Handler) GetAllTransactions(w http.ResponseWriter, r *http.Request) {
	page, _ := strconv.Atoi(r.URL.Query().Get("page"))
	if page < 1 {
		page = 1
	}
	pageSize, _ := strconv.Atoi(r.URL.Query().Get("page_size"))
	if pageSize < 1 {
		pageSize = 20
	}

	transactions, total, err := h.svc.GetAllTransactions(page, pageSize)
	if err != nil {
		h.utilHandler.SendError(w, err.Error(), http.StatusInternalServerError)
		return
	}

	h.utilHandler.SendData(w, map[string]interface{}{
		"transactions": transactions,
		"total":        total,
		"page":         page,
		"page_size":    pageSize,
		"total_pages":  (total + pageSize - 1) / pageSize,
	}, http.StatusOK)
}
