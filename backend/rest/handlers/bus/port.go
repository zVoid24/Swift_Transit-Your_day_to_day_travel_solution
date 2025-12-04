package bus

import "swift_transit/domain"

type Service interface {
	FindBus(start, end string) ([]domain.Bus, error)
	Login(regNum, password string) (*domain.BusCredential, error)
	ValidateTicket(ticketID int64, routeID int64) error
}
