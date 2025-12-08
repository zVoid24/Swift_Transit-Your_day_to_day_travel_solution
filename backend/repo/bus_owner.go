package repo

import (
	"database/sql"
	"fmt"
	"swift_transit/domain"
	"swift_transit/utils"
)

type BusOwnerRepo interface {
	Create(owner domain.BusOwner) error
	GetByUsername(username string) (*domain.BusOwner, error)
	CountBusesByRoute(ownerId int64, routeId int64) (int, error)
	GetBusesByOwner(ownerId int64) ([]domain.BusCredential, error)
	GetAnalytics(ownerId int64) (*domain.BusOwnerAnalytics, error)
	GetPerBusAnalytics(ownerId int64) ([]domain.BusAnalytics, error)
}

type busOwnerRepo struct {
	db          *sql.DB
	utilHandler *utils.Handler
}

func NewBusOwnerRepo(db *sql.DB, utilHandler *utils.Handler) BusOwnerRepo {
	return &busOwnerRepo{
		db:          db,
		utilHandler: utilHandler,
	}
}

func (r *busOwnerRepo) Create(owner domain.BusOwner) error {
	query := `INSERT INTO bus_owners (username, password) VALUES ($1, $2)`
	_, err := r.db.Exec(query, owner.Username, owner.Password)
	if err != nil {
		return fmt.Errorf("failed to create bus owner: %w", err)
	}
	return nil
}

func (r *busOwnerRepo) GetByUsername(username string) (*domain.BusOwner, error) {
	query := `SELECT id, username, password, created_at FROM bus_owners WHERE username = $1`
	var owner domain.BusOwner
	err := r.db.QueryRow(query, username).Scan(&owner.Id, &owner.Username, &owner.Password, &owner.CreatedAt)
	if err != nil {
		if err == sql.ErrNoRows {
			return nil, fmt.Errorf("bus owner not found")
		}
		return nil, fmt.Errorf("failed to get bus owner: %w", err)
	}
	return &owner, nil
}

func (r *busOwnerRepo) CountBusesByRoute(ownerId int64, routeId int64) (int, error) {
	query := `SELECT COUNT(*) FROM bus_credentials WHERE owner_id = $1 AND (route_id_up = $2 OR route_id_down = $2)`
	var count int
	err := r.db.QueryRow(query, ownerId, routeId).Scan(&count)
	if err != nil {
		return 0, fmt.Errorf("failed to count buses: %w", err)
	}
	return count, nil
}

func (r *busOwnerRepo) GetBusesByOwner(ownerId int64) ([]domain.BusCredential, error) {
	query := `SELECT id, registration_number, password, route_id_up, route_id_down, owner_id FROM bus_credentials WHERE owner_id = $1`
	rows, err := r.db.Query(query, ownerId)
	if err != nil {
		return nil, fmt.Errorf("failed to get buses: %w", err)
	}
	defer rows.Close()

	var buses []domain.BusCredential
	for rows.Next() {
		var bus domain.BusCredential
		if err := rows.Scan(&bus.Id, &bus.RegistrationNumber, &bus.Password, &bus.RouteIdUp, &bus.RouteIdDown, &bus.OwnerId); err != nil {
			return nil, err
		}
		buses = append(buses, bus)
	}
	return buses, nil
}

func (r *busOwnerRepo) GetAnalytics(ownerId int64) (*domain.BusOwnerAnalytics, error) {
	query := `
		SELECT 
			COALESCE(SUM(t.fare), 0) as total_revenue,
			COUNT(t.id) as total_tickets,
			COALESCE(SUM(CASE WHEN t.created_at >= CURRENT_DATE THEN t.fare ELSE 0 END), 0) as today_revenue,
			COUNT(CASE WHEN t.created_at >= CURRENT_DATE THEN 1 END) as today_tickets,
			COALESCE(SUM(CASE WHEN t.created_at >= DATE_TRUNC('week', CURRENT_DATE) THEN t.fare ELSE 0 END), 0) as weekly_revenue,
			COUNT(CASE WHEN t.created_at >= DATE_TRUNC('week', CURRENT_DATE) THEN 1 END) as weekly_tickets,
			COALESCE(SUM(CASE WHEN t.created_at >= DATE_TRUNC('month', CURRENT_DATE) THEN t.fare ELSE 0 END), 0) as monthly_revenue,
			COUNT(CASE WHEN t.created_at >= DATE_TRUNC('month', CURRENT_DATE) THEN 1 END) as monthly_tickets
		FROM tickets t
		JOIN bus_credentials b ON t.registration_number = b.registration_number
		WHERE b.owner_id = $1 AND t.payment_status = 'paid'
	`

	var analytics domain.BusOwnerAnalytics
	err := r.db.QueryRow(query, ownerId).Scan(
		&analytics.TotalRevenue,
		&analytics.TotalTickets,
		&analytics.Today.Revenue,
		&analytics.Today.Tickets,
		&analytics.Weekly.Revenue,
		&analytics.Weekly.Tickets,
		&analytics.Monthly.Revenue,
		&analytics.Monthly.Tickets,
	)
	if err != nil {
		return nil, fmt.Errorf("failed to get analytics: %w", err)
	}

	return &analytics, nil
}

func (r *busOwnerRepo) GetPerBusAnalytics(ownerId int64) ([]domain.BusAnalytics, error) {
	query := `
		SELECT 
			b.registration_number,
			COUNT(t.id) as tickets,
			COALESCE(SUM(t.fare), 0) as revenue
		FROM bus_credentials b
		LEFT JOIN tickets t ON t.registration_number = b.registration_number AND t.payment_status = 'paid'
		WHERE b.owner_id = $1
		GROUP BY b.registration_number
		ORDER BY revenue DESC
	`

	rows, err := r.db.Query(query, ownerId)
	if err != nil {
		return nil, fmt.Errorf("failed to get per-bus analytics: %w", err)
	}
	defer rows.Close()

	var analytics []domain.BusAnalytics
	for rows.Next() {
		var busAnalytics domain.BusAnalytics
		if err := rows.Scan(&busAnalytics.RegistrationNumber, &busAnalytics.Tickets, &busAnalytics.Revenue); err != nil {
			return nil, err
		}
		analytics = append(analytics, busAnalytics)
	}

	return analytics, nil
}
