package admin

import "net/http"

func (h *Handler) RegisterRoutes(mux *http.ServeMux) {
	// Public routes
	mux.Handle("POST /admin/auth/login", http.HandlerFunc(h.Login))

	// Protected routes - require admin authentication
	// Dashboard
	mux.Handle("GET /admin/dashboard/stats", h.mngr.With(http.HandlerFunc(h.GetDashboardStats), h.middlewareHandler.Authenticate))

	// Users
	mux.Handle("GET /admin/users", h.mngr.With(http.HandlerFunc(h.GetAllUsers), h.middlewareHandler.Authenticate))
	mux.Handle("GET /admin/users/{id}", h.mngr.With(http.HandlerFunc(h.GetUserByID), h.middlewareHandler.Authenticate))
	mux.Handle("PUT /admin/users/{id}", h.mngr.With(http.HandlerFunc(h.UpdateUser), h.middlewareHandler.Authenticate))
	mux.Handle("DELETE /admin/users/{id}", h.mngr.With(http.HandlerFunc(h.DeleteUser), h.middlewareHandler.Authenticate))

	// Bus Owners
	mux.Handle("GET /admin/bus-owners", h.mngr.With(http.HandlerFunc(h.GetAllBusOwners), h.middlewareHandler.Authenticate))
	mux.Handle("POST /admin/bus-owners", h.mngr.With(http.HandlerFunc(h.CreateBusOwner), h.middlewareHandler.Authenticate))
	mux.Handle("PUT /admin/bus-owners/{id}", h.mngr.With(http.HandlerFunc(h.UpdateBusOwner), h.middlewareHandler.Authenticate))
	mux.Handle("DELETE /admin/bus-owners/{id}", h.mngr.With(http.HandlerFunc(h.DeleteBusOwner), h.middlewareHandler.Authenticate))

	// Buses
	mux.Handle("GET /admin/buses", h.mngr.With(http.HandlerFunc(h.GetAllBuses), h.middlewareHandler.Authenticate))
	mux.Handle("PUT /admin/buses/{id}", h.mngr.With(http.HandlerFunc(h.UpdateBus), h.middlewareHandler.Authenticate))
	mux.Handle("DELETE /admin/buses/{id}", h.mngr.With(http.HandlerFunc(h.DeleteBus), h.middlewareHandler.Authenticate))

	// Routes
	mux.Handle("GET /admin/routes", h.mngr.With(http.HandlerFunc(h.GetAllRoutes), h.middlewareHandler.Authenticate))
	mux.Handle("DELETE /admin/routes/{id}", h.mngr.With(http.HandlerFunc(h.DeleteRoute), h.middlewareHandler.Authenticate))

	// Tickets
	mux.Handle("GET /admin/tickets", h.mngr.With(http.HandlerFunc(h.GetAllTickets), h.middlewareHandler.Authenticate))

	// Transactions
	mux.Handle("GET /admin/transactions", h.mngr.With(http.HandlerFunc(h.GetAllTransactions), h.middlewareHandler.Authenticate))
}
