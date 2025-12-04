package ticket

import (
	"swift_transit/domain"
)

type BuyTicketRequest struct {
	UserId           int64  `json:"-"` // Extracted from JWT
	RouteId          int64  `json:"route_id"`
	BusName          string `json:"bus_name"`
	StartDestination string `json:"start_destination"`
	EndDestination   string `json:"end_destination"`
	PaymentMethod    string `json:"payment_method"` // "wallet" or "gateway"
}

type TicketRequestMessage struct {
	UserId           int64   `json:"user_id"`
	RouteId          int64   `json:"route_id"`
	BusName          string  `json:"bus_name"`
	StartDestination string  `json:"start_destination"`
	EndDestination   string  `json:"end_destination"`
	Fare             float64 `json:"fare"`
	PaymentMethod    string  `json:"payment_method"`
}

type BuyTicketResponse struct {
	Ticket      *domain.Ticket `json:"ticket,omitempty"`
	PaymentURL  string         `json:"payment_url,omitempty"`
	DownloadURL string         `json:"download_url,omitempty"`
	Message     string         `json:"message"`
	TrackingID  string         `json:"tracking_id,omitempty"`
}

type Service interface {
	BuyTicket(req BuyTicketRequest) (*BuyTicketResponse, error)
	UpdatePaymentStatus(id int64) error
	DownloadTicket(id int64) ([]byte, error)
	GetTicketStatus(trackingID string) (*BuyTicketResponse, error)
	ValidatePayment(valID string, tranID string, amount float64) (bool, error)
	GetByUserID(userId int64, limit, offset int) ([]domain.Ticket, int, error)
	ValidateTicket(id int64) error
}

type TicketRepo interface {
	Create(ticket domain.Ticket) (*domain.Ticket, error)
	UpdateStatus(id int64, status bool) error
	Get(id int64) (*domain.Ticket, error)
	CalculateFare(routeId int64, start, end string) (float64, error)
	GetByUserID(userId int64, limit, offset int) ([]domain.Ticket, int, error)
	ValidateTicket(id int64) error
}
