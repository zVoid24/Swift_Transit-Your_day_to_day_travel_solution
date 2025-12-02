package user

import (
	"context"
	"swift_transit/domain"
	"swift_transit/rest/handlers/user"
)

type Service interface {
	user.Service //embedding
}

// UserRepo interface
type UserRepo interface {
	Find(mobile, password string) (*domain.User, error) // login
	Create(user domain.User) (*domain.User, error)      // create new user
	Info(ctx context.Context) (*domain.User, error)
	DeductBalance(id int64, amount float64) error
	UpdatePassword(email, newPassword string) error
	FindByEmail(email string) (*domain.User, error)
}
