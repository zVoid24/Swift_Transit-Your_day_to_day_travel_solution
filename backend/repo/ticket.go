package repo

import (
	"swift_transit/domain"
	"swift_transit/ticket"
	"swift_transit/utils"

	"github.com/jmoiron/sqlx"
)

type TicketRepo interface {
	ticket.TicketRepo
	GetByUserID(userId int64) ([]domain.Ticket, error)
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
		INSERT INTO tickets (user_id, route_id, bus_name, start_destination, end_destination, fare, paid_status, qr_code, created_at)
		VALUES (:user_id, :route_id, :bus_name, :start_destination, :end_destination, :fare, :paid_status, :qr_code, :created_at)
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
	query := `UPDATE tickets SET paid_status = $1 WHERE id = $2`
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

func (r *ticketRepo) GetByUserID(userId int64) ([]domain.Ticket, error) {
	var tickets []domain.Ticket
	query := `SELECT * FROM tickets WHERE user_id = $1 ORDER BY created_at DESC`
	err := r.dbCon.Select(&tickets, query, userId)
	if err != nil {
		return nil, err
	}
	return tickets, nil
}

func (r *ticketRepo) ValidateTicket(id int64) error {
	query := `UPDATE tickets SET checked = TRUE WHERE id = $1`
	_, err := r.dbCon.Exec(query, id)
	return err
}
