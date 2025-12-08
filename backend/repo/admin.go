package repo

import (
	"database/sql"
	"fmt"
	"swift_transit/domain"

	"golang.org/x/crypto/bcrypt"
)

type AdminRepo interface {
	GetByUsername(username string) (*domain.Admin, error)
	GetAllUsers(limit, offset int) ([]domain.User, int, error)
	GetUserByID(id int64) (*domain.User, error)
	UpdateUser(user domain.User) error
	DeleteUser(id int64) error

	// Dashboard Analytics
	GetDashboardStats() (map[string]interface{}, error)

	// Bus Owners
	GetAllBusOwners(limit, offset int) ([]domain.BusOwner, int, error)
	GetBusOwnerByID(id int64) (*domain.BusOwner, error)
	CreateBusOwner(owner domain.BusOwner) error
	UpdateBusOwner(owner domain.BusOwner) error
	DeleteBusOwner(id int64) error

	// Buses
	GetAllBuses(limit, offset int) ([]domain.BusCredential, int, error)
	GetBusByID(id int64) (*domain.BusCredential, error)
	UpdateBus(bus domain.BusCredential) error
	DeleteBus(id int64) error

	// Routes
	GetAllRoutes(limit, offset int) ([]domain.Route, int, error)
	DeleteRoute(id int64) error

	// Tickets
	GetAllTickets(limit, offset int) ([]domain.Ticket, int, error)

	// Transactions
	GetAllTransactions(limit, offset int) ([]domain.Transaction, int, error)
}

type adminRepo struct {
	db *sql.DB
}

func NewAdminRepo(db *sql.DB) AdminRepo {
	return &adminRepo{db: db}
}

func (r *adminRepo) GetByUsername(username string) (*domain.Admin, error) {
	query := `SELECT id, username, password, created_at FROM admins WHERE username = $1`
	var admin domain.Admin
	err := r.db.QueryRow(query, username).Scan(&admin.Id, &admin.Username, &admin.Password, &admin.CreatedAt)
	if err != nil {
		if err == sql.ErrNoRows {
			return nil, fmt.Errorf("admin not found")
		}
		return nil, fmt.Errorf("failed to get admin: %w", err)
	}
	return &admin, nil
}

func (r *adminRepo) GetAllUsers(limit, offset int) ([]domain.User, int, error) {
	var total int
	countQuery := `SELECT COUNT(*) FROM users`
	err := r.db.QueryRow(countQuery).Scan(&total)
	if err != nil {
		return nil, 0, fmt.Errorf("failed to count users: %w", err)
	}

	query := `SELECT id, name, mobile, nid, email, is_student, balance FROM users 
	          ORDER BY id DESC LIMIT $1 OFFSET $2`
	rows, err := r.db.Query(query, limit, offset)
	if err != nil {
		return nil, 0, fmt.Errorf("failed to get users: %w", err)
	}
	defer rows.Close()

	var users []domain.User
	for rows.Next() {
		var user domain.User
		err := rows.Scan(&user.Id, &user.Name, &user.Mobile, &user.NID, &user.Email, &user.IsStudent, &user.Balance)
		if err != nil {
			return nil, 0, err
		}
		users = append(users, user)
	}

	return users, total, nil
}

func (r *adminRepo) GetUserByID(id int64) (*domain.User, error) {
	query := `SELECT id, name, mobile, nid, email, is_student, balance FROM users WHERE id = $1`
	var user domain.User
	err := r.db.QueryRow(query, id).Scan(&user.Id, &user.Name, &user.Mobile, &user.NID, &user.Email, &user.IsStudent, &user.Balance)
	if err != nil {
		if err == sql.ErrNoRows {
			return nil, fmt.Errorf("user not found")
		}
		return nil, fmt.Errorf("failed to get user: %w", err)
	}
	return &user, nil
}

func (r *adminRepo) UpdateUser(user domain.User) error {
	query := `UPDATE users SET name = $1, mobile = $2, nid = $3, email = $4, is_student = $5, balance = $6 
	          WHERE id = $7`
	_, err := r.db.Exec(query, user.Name, user.Mobile, user.NID, user.Email, user.IsStudent, user.Balance, user.Id)
	if err != nil {
		return fmt.Errorf("failed to update user: %w", err)
	}
	return nil
}

func (r *adminRepo) DeleteUser(id int64) error {
	query := `DELETE FROM users WHERE id = $1`
	_, err := r.db.Exec(query, id)
	if err != nil {
		return fmt.Errorf("failed to delete user: %w", err)
	}
	return nil
}

// Dashboard Analytics
func (r *adminRepo) GetDashboardStats() (map[string]interface{}, error) {
	stats := make(map[string]interface{})

	// Total users
	var totalUsers int
	r.db.QueryRow(`SELECT COUNT(*) FROM users`).Scan(&totalUsers)
	stats["total_users"] = totalUsers

	// Total bus owners
	var totalBusOwners int
	r.db.QueryRow(`SELECT COUNT(*) FROM bus_owners`).Scan(&totalBusOwners)
	stats["total_bus_owners"] = totalBusOwners

	// Total buses
	var totalBuses int
	r.db.QueryRow(`SELECT COUNT(*) FROM bus_credentials`).Scan(&totalBuses)
	stats["total_buses"] = totalBuses

	// Total routes
	var totalRoutes int
	r.db.QueryRow(`SELECT COUNT(*) FROM routes`).Scan(&totalRoutes)
	stats["total_routes"] = totalRoutes

	// Total tickets
	var totalTickets int
	r.db.QueryRow(`SELECT COUNT(*) FROM tickets`).Scan(&totalTickets)
	stats["total_tickets"] = totalTickets

	// Total revenue
	var totalRevenue float64
	r.db.QueryRow(`SELECT COALESCE(SUM(fare), 0) FROM tickets WHERE payment_status = 'paid'`).Scan(&totalRevenue)
	stats["total_revenue"] = totalRevenue

	// Today's tickets
	var todayTickets int
	r.db.QueryRow(`SELECT COUNT(*) FROM tickets WHERE created_at >= CURRENT_DATE`).Scan(&todayTickets)
	stats["today_tickets"] = todayTickets

	// Today's revenue
	var todayRevenue float64
	r.db.QueryRow(`SELECT COALESCE(SUM(fare), 0) FROM tickets WHERE payment_status = 'paid' AND created_at >= CURRENT_DATE`).Scan(&todayRevenue)
	stats["today_revenue"] = todayRevenue

	return stats, nil
}

// Bus Owners
func (r *adminRepo) GetAllBusOwners(limit, offset int) ([]domain.BusOwner, int, error) {
	var total int
	r.db.QueryRow(`SELECT COUNT(*) FROM bus_owners`).Scan(&total)

	query := `SELECT id, username, created_at FROM bus_owners ORDER BY id DESC LIMIT $1 OFFSET $2`
	rows, err := r.db.Query(query, limit, offset)
	if err != nil {
		return nil, 0, err
	}
	defer rows.Close()

	var owners []domain.BusOwner
	for rows.Next() {
		var owner domain.BusOwner
		rows.Scan(&owner.Id, &owner.Username, &owner.CreatedAt)
		owners = append(owners, owner)
	}
	return owners, total, nil
}

func (r *adminRepo) GetBusOwnerByID(id int64) (*domain.BusOwner, error) {
	var owner domain.BusOwner
	query := `SELECT id, username, created_at FROM bus_owners WHERE id = $1`
	err := r.db.QueryRow(query, id).Scan(&owner.Id, &owner.Username, &owner.CreatedAt)
	if err != nil {
		return nil, err
	}
	return &owner, nil
}

func (r *adminRepo) CreateBusOwner(owner domain.BusOwner) error {
	hashedPassword, err := bcrypt.GenerateFromPassword([]byte(owner.Password), bcrypt.DefaultCost)
	if err != nil {
		return err
	}
	query := `INSERT INTO bus_owners (username, password) VALUES ($1, $2)`
	_, err = r.db.Exec(query, owner.Username, string(hashedPassword))
	return err
}

func (r *adminRepo) UpdateBusOwner(owner domain.BusOwner) error {
	if owner.Password != "" {
		hashedPassword, err := bcrypt.GenerateFromPassword([]byte(owner.Password), bcrypt.DefaultCost)
		if err != nil {
			return err
		}
		query := `UPDATE bus_owners SET username = $1, password = $2 WHERE id = $3`
		_, err = r.db.Exec(query, owner.Username, string(hashedPassword), owner.Id)
		return err
	}
	query := `UPDATE bus_owners SET username = $1 WHERE id = $2`
	_, err := r.db.Exec(query, owner.Username, owner.Id)
	return err
}

func (r *adminRepo) DeleteBusOwner(id int64) error {
	_, err := r.db.Exec(`DELETE FROM bus_owners WHERE id = $1`, id)
	return err
}

// Buses
func (r *adminRepo) GetAllBuses(limit, offset int) ([]domain.BusCredential, int, error) {
	var total int
	r.db.QueryRow(`SELECT COUNT(*) FROM bus_credentials`).Scan(&total)

	query := `SELECT id, registration_number, route_id_up, route_id_down, owner_id FROM bus_credentials ORDER BY id DESC LIMIT $1 OFFSET $2`
	rows, err := r.db.Query(query, limit, offset)
	if err != nil {
		return nil, 0, err
	}
	defer rows.Close()

	var buses []domain.BusCredential
	for rows.Next() {
		var bus domain.BusCredential
		var ownerID sql.NullInt64
		rows.Scan(&bus.Id, &bus.RegistrationNumber, &bus.RouteIdUp, &bus.RouteIdDown, &ownerID)
		if ownerID.Valid {
			id := ownerID.Int64
			bus.OwnerId = &id
		}
		buses = append(buses, bus)
	}
	return buses, total, nil
}

func (r *adminRepo) GetBusByID(id int64) (*domain.BusCredential, error) {
	var bus domain.BusCredential
	var ownerID sql.NullInt64
	query := `SELECT id, registration_number, route_id_up, route_id_down, owner_id FROM bus_credentials WHERE id = $1`
	err := r.db.QueryRow(query, id).Scan(&bus.Id, &bus.RegistrationNumber, &bus.RouteIdUp, &bus.RouteIdDown, &ownerID)
	if err != nil {
		return nil, err
	}
	if ownerID.Valid {
		id := ownerID.Int64
		bus.OwnerId = &id
	}
	return &bus, nil
}

func (r *adminRepo) UpdateBus(bus domain.BusCredential) error {
	query := `UPDATE bus_credentials SET registration_number = $1, route_id_up = $2, route_id_down = $3 WHERE id = $4`
	_, err := r.db.Exec(query, bus.RegistrationNumber, bus.RouteIdUp, bus.RouteIdDown, bus.Id)
	return err
}

func (r *adminRepo) DeleteBus(id int64) error {
	_, err := r.db.Exec(`DELETE FROM bus_credentials WHERE id = $1`, id)
	return err
}

// Routes
func (r *adminRepo) GetAllRoutes(limit, offset int) ([]domain.Route, int, error) {
	var total int
	r.db.QueryRow(`SELECT COUNT(*) FROM routes`).Scan(&total)

	query := `SELECT id, name FROM routes ORDER BY id DESC LIMIT $1 OFFSET $2`
	rows, err := r.db.Query(query, limit, offset)
	if err != nil {
		return nil, 0, err
	}
	defer rows.Close()

	var routes []domain.Route
	for rows.Next() {
		var route domain.Route
		rows.Scan(&route.Id, &route.Name)
		routes = append(routes, route)
	}
	return routes, total, nil
}

func (r *adminRepo) DeleteRoute(id int64) error {
	_, err := r.db.Exec(`DELETE FROM routes WHERE id = $1`, id)
	return err
}

// Tickets
func (r *adminRepo) GetAllTickets(limit, offset int) ([]domain.Ticket, int, error) {
	var total int
	r.db.QueryRow(`SELECT COUNT(*) FROM tickets`).Scan(&total)

	query := `SELECT id, user_id, route_id, registration_number, start_destination, end_destination, 
	          fare, payment_status, created_at FROM tickets ORDER BY id DESC LIMIT $1 OFFSET $2`
	rows, err := r.db.Query(query, limit, offset)
	if err != nil {
		return nil, 0, err
	}
	defer rows.Close()

	var tickets []domain.Ticket
	for rows.Next() {
		var ticket domain.Ticket
		rows.Scan(&ticket.Id, &ticket.UserId, &ticket.RouteId, &ticket.RegistrationNumber,
			&ticket.StartDestination, &ticket.EndDestination, &ticket.Fare, &ticket.PaymentStatus, &ticket.CreatedAt)
		tickets = append(tickets, ticket)
	}
	return tickets, total, nil
}

// Transactions
func (r *adminRepo) GetAllTransactions(limit, offset int) ([]domain.Transaction, int, error) {
	var total int
	r.db.QueryRow(`SELECT COUNT(*) FROM transactions`).Scan(&total)

	query := `SELECT id, user_id, amount, type, description, payment_method, created_at 
	          FROM transactions ORDER BY id DESC LIMIT $1 OFFSET $2`
	rows, err := r.db.Query(query, limit, offset)
	if err != nil {
		return nil, 0, err
	}
	defer rows.Close()

	var transactions []domain.Transaction
	for rows.Next() {
		var txn domain.Transaction
		rows.Scan(&txn.ID, &txn.UserID, &txn.Amount, &txn.Type, &txn.Description, &txn.PaymentMethod, &txn.CreatedAt)
		transactions = append(transactions, txn)
	}
	return transactions, total, nil
}
