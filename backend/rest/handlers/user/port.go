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
	UpdatePassword(email, newPassword string) error
	FindByEmail(email string) (*domain.User, error)
	UpdateProfile(id int64, name, email, mobile string) (*domain.User, error)
	ChangePassword(id int64, currentPassword, newPassword string) error
	GetWithPassword(id int64) (*domain.User, error)
	ToggleRFIDStatus(userID int64, active bool) error
}
