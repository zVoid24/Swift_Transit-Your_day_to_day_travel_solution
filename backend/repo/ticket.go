package repo

import (
	"time"

	"swift_transit/domain"
	"swift_transit/ticket"
	"swift_transit/utils"

	"github.com/jmoiron/sqlx"
)

type TicketRepo interface {
	ticket.TicketRepo
	GetByUserID(userId int64, limit, offset int) ([]domain.Ticket, int, error)
	CountActiveTicketsByRoute(userId int64, routeId int64) (int, error)
	UpdateBatchPaymentStatus(batchID string, paid bool, status string, markUsed bool) error
	CancelTicket(id int64, cancelledAt time.Time, status string) error
}

type ticketRepo struct {
	dbCon       *sqlx.DB
	utilHandler *utils.Handler
}

func NewTicketRepo(dbcon *sqlx.DB, utilHandler *utils.Handler) TicketRepo {
	return &ticketRepo{
		dbCon:       dbcon,
		utilHandler: utilHandler,
	}
}

func (r *ticketRepo) Create(ticket domain.Ticket) (*domain.Ticket, error) {
	query := `
                INSERT INTO tickets (user_id, route_id, bus_name, start_destination, end_destination, fare, paid_status, checked, qr_code, created_at, batch_id, payment_method, payment_reference, payment_used, payment_status, cancelled_at)
                VALUES (:user_id, :route_id, :bus_name, :start_destination, :end_destination, :fare, :paid_status, :checked, :qr_code, :created_at, :batch_id, :payment_method, :payment_reference, :payment_used, :payment_status, :cancelled_at)
                RETURNING id
        `
	rows, err := r.dbCon.NamedQuery(query, ticket)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	if rows.Next() {
		err = rows.Scan(&ticket.Id)
		if err != nil {
			return nil, err
		}
	}

	return &ticket, nil
}

func (r *ticketRepo) UpdateStatus(id int64, status bool) error {
	query := `
                UPDATE tickets
                SET paid_status = $1,
                    payment_status = CASE WHEN $1 THEN 'paid' ELSE payment_status END,
                    payment_used = CASE WHEN $1 THEN TRUE ELSE payment_used END
                WHERE batch_id = (SELECT batch_id FROM tickets WHERE id = $2)
        `
	_, err := r.dbCon.Exec(query, status, id)
	return err
}

func (r *ticketRepo) Get(id int64) (*domain.Ticket, error) {
	var ticket domain.Ticket
	query := `SELECT * FROM tickets WHERE id = $1`
	err := r.dbCon.Get(&ticket, query, id)
	if err != nil {
		return nil, err
	}
	return &ticket, nil
}

func (r *ticketRepo) CalculateFare(routeId int64, start, end string) (float64, error) {
	var fare float64
	query := `
		SELECT 
			GREATEST(10, (ST_Length(
				ST_LineSubstring(
					r.geom, 
					ST_LineLocatePoint(r.geom, s1.geom), 
					ST_LineLocatePoint(r.geom, s2.geom)
				)::geography
			) / 1000)*2.5) as fare
		FROM routes r
		JOIN stops s1 ON r.id = s1.route_id
		JOIN stops s2 ON r.id = s2.route_id
		WHERE r.id = $1 AND s1.name = $2 AND s2.name = $3
	`
	err := r.dbCon.Get(&fare, query, routeId, start, end)
	if err != nil {
		return 0, err
	}
	return fare, nil
}

func (r *ticketRepo) GetByUserID(userId int64, limit, offset int) ([]domain.Ticket, int, error) {
	var tickets []domain.Ticket
	var total int

	countQuery := `SELECT COUNT(*) FROM tickets WHERE user_id = $1`
	if err := r.dbCon.Get(&total, countQuery, userId); err != nil {
		return nil, 0, err
	}

	query := `SELECT * FROM tickets WHERE user_id = $1 ORDER BY created_at DESC LIMIT $2 OFFSET $3`
	err := r.dbCon.Select(&tickets, query, userId, limit, offset)
	if err != nil {
		return nil, 0, err
	}
	return tickets, total, nil
}

func (r *ticketRepo) CountActiveTicketsByRoute(userId int64, routeId int64) (int, error) {
	var count int
	query := `
                SELECT COUNT(*)
                FROM tickets
                WHERE user_id = $1
                  AND route_id = $2
                  AND cancelled_at IS NULL
                  AND checked = FALSE
        `
	if err := r.dbCon.Get(&count, query, userId, routeId); err != nil {
		return 0, err
	}
	return count, nil
}

func (r *ticketRepo) UpdateBatchPaymentStatus(batchID string, paid bool, status string, markUsed bool) error {
	query := `
                UPDATE tickets
                SET paid_status = $1,
                    payment_status = $2,
                    payment_used = CASE WHEN $3 THEN TRUE ELSE payment_used END,
                    cancelled_at = CASE WHEN $1 = FALSE THEN COALESCE(cancelled_at, NOW()) ELSE cancelled_at END
                WHERE batch_id = $4
        `
	_, err := r.dbCon.Exec(query, paid, status, markUsed, batchID)
	return err
}

func (r *ticketRepo) CancelTicket(id int64, cancelledAt time.Time, status string) error {
	query := `
                UPDATE tickets
                SET cancelled_at = $1,
                    payment_status = $2
                WHERE id = $3
        `
	_, err := r.dbCon.Exec(query, cancelledAt, status, id)
	return err
}

func (r *ticketRepo) ValidateTicket(id int64) error {
	query := `UPDATE tickets SET checked = TRUE WHERE id = $1`
	_, err := r.dbCon.Exec(query, id)
	return err
}

func (r *ticketRepo) GetBatchCount(batchID string) (int, error) {
	var count int
	query := `SELECT COUNT(*) FROM tickets WHERE batch_id = $1`
	err := r.dbCon.Get(&count, query, batchID)
	return count, err
}

func (r *ticketRepo) GetStop(routeId int64, stopName string) (*domain.Stop, error) {
	var stop domain.Stop
	query := `
		SELECT 
			id, 
			route_id, 
			name, 
			stop_order, 
			ST_X(geom::geometry) as lon, 
			ST_Y(geom::geometry) as lat, 
			COALESCE(ST_AsGeoJSON(area_geom), '') as area_geom 
		FROM stops 
		WHERE route_id = $1 AND name = $2
	`
	err := r.dbCon.Get(&stop, query, routeId, stopName)
	if err != nil {
		return nil, err
	}
	return &stop, nil
}

func (r *ticketRepo) GetByQRCode(qrCode string) (*domain.Ticket, error) {
	var ticket domain.Ticket
	query := `SELECT * FROM tickets WHERE qr_code = $1`
	err := r.dbCon.Get(&ticket, query, qrCode)
	if err != nil {
		return nil, err
	}
	return &ticket, nil
}

func (r *ticketRepo) GetLatestTicket(userId int64, routeId int64) (*domain.Ticket, error) {
	var ticket domain.Ticket
	query := `
		SELECT * FROM tickets 
		WHERE user_id = $1 AND route_id = $2 
		ORDER BY created_at DESC 
		LIMIT 1
	`
	err := r.dbCon.Get(&ticket, query, userId, routeId)
	if err != nil {
		return nil, err
	}
	return &ticket, nil
}
