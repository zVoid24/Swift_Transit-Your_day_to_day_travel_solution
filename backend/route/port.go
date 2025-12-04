package route

import (
	"swift_transit/domain"
)

type Service interface {
	Create(route domain.Route) (*domain.Route, error)
	FindAll() ([]domain.Route, error)
	FindByID(id int64) (*domain.Route, error)
	FindRoute(start, end string) (*domain.Route, error)
	SearchByName(query string) ([]domain.Route, error)
	SearchStops(query string) ([]string, error)
}

type RouteRepo interface {
	Create(route domain.Route) (*domain.Route, error)
	FindAll() ([]domain.Route, error)
	FindByID(id int64) (*domain.Route, error)
	FindRoute(start, end string) (*domain.Route, error)
	SearchByName(query string) ([]domain.Route, error)
	SearchStops(query string) ([]string, error)
}
