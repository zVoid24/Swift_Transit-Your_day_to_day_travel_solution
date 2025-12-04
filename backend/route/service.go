package route

import "swift_transit/domain"

type service struct {
	repo RouteRepo
}

func NewService(repo RouteRepo) Service {
	return &service{
		repo: repo,
	}
}

func (svc *service) Create(route domain.Route) (*domain.Route, error) {
	createdRoute, err := svc.repo.Create(route)
	if err != nil {
		return nil, err
	}
	return createdRoute, nil
}
func (svc *service) FindAll() ([]domain.Route, error) {
	return nil, nil
}
func (svc *service) FindByID(id int64) (*domain.Route, error) {
	return svc.repo.FindByID(id)
}

func (svc *service) FindRoute(start, end string) (*domain.Route, error) {
	return svc.repo.FindRoute(start, end)
}

func (svc *service) SearchStops(query string) ([]string, error) {
	return svc.repo.SearchStops(query)
}

func (svc *service) SearchByName(query string) ([]domain.Route, error) {
	return svc.repo.SearchByName(query)
}
