package user

import (
	"context"
	"swift_transit/domain"
)

type service struct {
	userRepo UserRepo
}

func NewService(usrRepo UserRepo) Service {
	return &service{
		userRepo: usrRepo,
	}
}

func (svc *service) Info(ctx context.Context) (*domain.User, error) {
	usr, err := svc.userRepo.Info(ctx)
	if err != nil {
		return nil, err
	}
	if usr == nil {
		return nil, nil
	}
	return usr, nil
}

func (svc *service) Create(user domain.User) (*domain.User, error) {
	usr, err := svc.userRepo.Create(user)
	if err != nil {
		return nil, err
	}
	if usr == nil {
		return nil, nil
	}
	return usr, nil
}
func (svc *service) Find(mobile string, password string) (*domain.User, error) {
	usr, err := svc.userRepo.Find(mobile, password)
	if err != nil {
		return nil, err
	}
	if usr == nil {
		return nil, nil
	}
	return usr, nil
}

func (svc *service) DeductBalance(id int64, amount float64) error {
	return svc.userRepo.DeductBalance(id, amount)
}

func (svc *service) UpdatePassword(email, newPassword string) error {
	return svc.userRepo.UpdatePassword(email, newPassword)
}

func (svc *service) FindByEmail(email string) (*domain.User, error) {
	return svc.userRepo.FindByEmail(email)
}
