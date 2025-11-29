package bus

import (
	"swift_transit/domain"
	"swift_transit/rest/handlers/bus"
)

type Service interface {
	bus.Service
}

type BusRepo interface {
	FindBus(start, end string) ([]domain.Bus, error)
}
