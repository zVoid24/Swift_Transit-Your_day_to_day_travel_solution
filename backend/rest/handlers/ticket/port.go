package ticket

import (
	"swift_transit/domain"
	"swift_transit/ticket"
)

type Service interface {
	BuyTicket(req ticket.BuyTicketRequest) (*ticket.BuyTicketResponse, error)
	UpdatePaymentStatus(id int64) error
	HandlePaymentResult(id int64, status string) (bool, error)
	GetTicketStatus(trackingID string) (*ticket.BuyTicketResponse, error)
	DownloadTicket(id int64) ([]byte, error)
	ValidatePayment(valID string, tranID string, amount float64) (bool, error)
	GetByUserID(userId int64, limit, offset int) ([]domain.Ticket, int, error)
	ValidateTicket(id int64) error
	GetPaymentStatus(ticketID int64) (string, error)
	CancelTicket(userID int64, ticketID int64) (float64, error)
	ProcessRFIDPayment(req ticket.RFIDPaymentRequest) (*ticket.RFIDPaymentResponse, error)
	CreateOverTravelTicket(originalTicketID int64, currentStop string, paymentCollected bool) (*domain.Ticket, error)
}
