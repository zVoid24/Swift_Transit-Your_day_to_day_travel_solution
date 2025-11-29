package bus

import "swift_transit/domain"

type service struct {
	repo BusRepo
}

func NewService(repo BusRepo) Service {
	return &service{
		repo: repo,
	}
}

func (svc *service) FindBus(start, end string) ([]domain.Bus, error) {
	return svc.repo.FindBus(start, end)
}
