package bus

import "swift_transit/domain"

type Service interface {
	FindBus(start, end string) ([]domain.Bus, error)
}
