package ticket

import (
	"time"

	"swift_transit/domain"
	"swift_transit/model"
)

type BuyTicketRequest struct {
	UserId           int64  `json:"-"` // Extracted from JWT
	RouteId          int64  `json:"route_id"`
	BusName          string `json:"bus_name"`
	StartDestination string `json:"start_destination"`
	EndDestination   string `json:"end_destination"`
	PaymentMethod    string `json:"payment_method"` // "wallet" or "gateway"
	Quantity         int    `json:"quantity"`
}

type TicketRequestMessage struct {
	UserId           int64   `json:"user_id"`
	RouteId          int64   `json:"route_id"`
	BusName          string  `json:"bus_name"`
	StartDestination string  `json:"start_destination"`
	EndDestination   string  `json:"end_destination"`
	Fare             float64 `json:"fare"`
	TotalFare        float64 `json:"total_fare"`
	Quantity         int     `json:"quantity"`
	BatchID          string  `json:"batch_id"`
	PaymentMethod    string  `json:"payment_method"`
}

type BuyTicketResponse struct {
	Ticket      *domain.Ticket `json:"ticket,omitempty"`
	TicketIDs   []int64        `json:"ticket_ids,omitempty"`
	PaymentURL  string         `json:"payment_url,omitempty"`
	DownloadURL string         `json:"download_url,omitempty"`
	Message     string         `json:"message"`
	TrackingID  string         `json:"tracking_id,omitempty"`
}

type CheckTicketStoppage struct {
	Name  string `json:"name"`
	Order int    `json:"order"`
}

type CheckTicketRequest struct {
	QRCode          string              `json:"qr_code"`
	RouteID         int64               `json:"route_id"`
	CurrentStoppage CheckTicketStoppage `json:"current_stoppage"`
}

type Service interface {
	BuyTicket(req BuyTicketRequest) (*BuyTicketResponse, error)
	UpdatePaymentStatus(id int64) error
	HandlePaymentResult(id int64, status string) (bool, error)
	DownloadTicket(id int64) ([]byte, error)
	GetTicketStatus(trackingID string) (*BuyTicketResponse, error)
	ValidatePayment(valID string, tranID string, amount float64) (bool, error)
	GetByUserID(userId int64, limit, offset int) ([]domain.Ticket, int, error)
	ValidateTicket(id int64) error
	GetPaymentStatus(ticketID int64) (string, error)
	CancelTicket(userID int64, ticketID int64) (float64, error)
	CreateTransaction(t model.Transaction) error
	CheckTicket(req CheckTicketRequest) (map[string]interface{}, error)
	ProcessRFIDPayment(req RFIDPaymentRequest) (*RFIDPaymentResponse, error)
	CreateOverTravelTicket(originalTicketID int64, currentStop string, paymentCollected bool) (*domain.Ticket, error)
}

type RFIDPaymentRequest struct {
	RFID             string `json:"rfid"`
	RouteID          int64  `json:"route_id"`
	BusName          string `json:"bus_name"`
	StartDestination string `json:"start_destination"`
	EndDestination   string `json:"end_destination"`
}

type RFIDPaymentResponse struct {
	Success  bool    `json:"success"`
	Status   string  `json:"status"` // SUCCESS, DUPLICATE, INACTIVE, INSUFFICIENT_BALANCE
	Message  string  `json:"message"`
	Balance  float64 `json:"balance"`
	Fare     float64 `json:"fare"`
	TicketID int64   `json:"ticket_id,omitempty"`
}

type TicketRepo interface {
	Create(ticket domain.Ticket) (*domain.Ticket, error)
	UpdateStatus(id int64, status bool) error
	Get(id int64) (*domain.Ticket, error)
	CalculateFare(routeId int64, start, end string) (float64, error)
	GetByUserID(userId int64, limit, offset int) ([]domain.Ticket, int, error)
	ValidateTicket(id int64) error
	CountActiveTicketsByRoute(userId int64, routeId int64) (int, error)
	UpdateBatchPaymentStatus(batchID string, paid bool, status string, markUsed bool) error
	CancelTicket(id int64, cancelledAt time.Time, status string) error
	GetBatchCount(batchID string) (int, error)
	GetStop(routeId int64, stopName string) (*domain.Stop, error)
	GetByQRCode(qrCode string) (*domain.Ticket, error)
	GetLatestTicket(userId int64, routeId int64) (*domain.Ticket, error)
}
