package user

import (
	"context"
	"fmt"
	"math"
	"swift_transit/domain"

	"golang.org/x/crypto/bcrypt"
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
	usr.Balance = float32(math.Round(float64(usr.Balance)*100) / 100)
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

func (svc *service) CreditBalance(id int64, amount float64) error {
	return svc.userRepo.CreditBalance(id, amount)
}

func (svc *service) UpdatePassword(email, newPassword string) error {
	return svc.userRepo.UpdatePassword(email, newPassword)
}

func (svc *service) FindByEmail(email string) (*domain.User, error) {
	return svc.userRepo.FindByEmail(email)
}

func (svc *service) UpdateProfile(id int64, name, email, mobile string) (*domain.User, error) {
	return svc.userRepo.UpdateProfile(id, name, email, mobile)
}

func (svc *service) ChangePassword(id int64, currentPassword, newPassword string) error {
	user, err := svc.userRepo.GetWithPassword(id)
	if err != nil {
		return err
	}

	if err := bcrypt.CompareHashAndPassword([]byte(user.Password), []byte(currentPassword)); err != nil {
		return fmt.Errorf("current password is incorrect")
	}

	return svc.userRepo.UpdatePasswordByID(id, newPassword)
}

func (svc *service) GetWithPassword(id int64) (*domain.User, error) {
	return svc.userRepo.GetWithPassword(id)
}

func (svc *service) ToggleRFIDStatus(userID int64, active bool) error {
	return svc.userRepo.ToggleRFIDStatus(userID, active)
}
