package route

import (
	"swift_transit/domain"
	"swift_transit/rest/handlers/route"
)

type Service interface {
	route.Service //embedding
}

type RouteRepo interface {
	FindAll() ([]domain.Route, error)
	FindByID(id int64) (*domain.Route, error)
	Create(route domain.Route) (*domain.Route, error)
}
