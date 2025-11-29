package user

import (
	"context"
	"swift_transit/domain"
)

type Service interface {
	Find(username string, password string) (*domain.User, error)
	Create(user domain.User) (*domain.User, error)
	Info(ctx context.Context) (*domain.User, error)
	DeductBalance(id int64, amount float64) error
}
