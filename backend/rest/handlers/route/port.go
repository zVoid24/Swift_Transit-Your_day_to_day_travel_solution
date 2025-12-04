package route

import "swift_transit/domain"

type Service interface {
	FindAll() ([]domain.Route, error)
	FindByID(id int64) (*domain.Route, error)
	Create(route domain.Route) (*domain.Route, error)
	FindRoute(start, end string) (*domain.Route, error)
	SearchByName(query string) ([]domain.Route, error)
	SearchStops(query string) ([]string, error)
}
