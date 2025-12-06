package bus

import (
	"swift_transit/domain"
	"swift_transit/ticket"
)

type Service interface {
	FindBus(start, end string) ([]domain.Bus, error)
	Login(regNum, password string, variant string) (*bus.BusLoginResult, error)
	Register(regNum, password string, routeIdUp, routeIdDown int64) (*domain.BusCredential, error)
	ValidateTicket(ticketID int64, routeID int64) error
	CheckTicket(req ticket.CheckTicketRequest) (map[string]interface{}, error)
}
