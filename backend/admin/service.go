package admin

import (
	"fmt"
	"swift_transit/domain"
	"swift_transit/repo"
	"swift_transit/utils"

	"golang.org/x/crypto/bcrypt"
)

type Service interface {
	Login(username, password string) (*domain.Admin, string, error)

	// Users
	GetAllUsers(page, pageSize int) ([]domain.User, int, error)
	GetUserByID(id int64) (*domain.User, error)
	UpdateUser(user domain.User) error
	DeleteUser(id int64) error

	// Dashboard
	GetDashboardStats() (map[string]interface{}, error)

	// Bus Owners
	GetAllBusOwners(page, pageSize int) ([]domain.BusOwner, int, error)
	GetBusOwnerByID(id int64) (*domain.BusOwner, error)
	CreateBusOwner(owner domain.BusOwner) error
	UpdateBusOwner(owner domain.BusOwner) error
	DeleteBusOwner(id int64) error

	// Buses
	GetAllBuses(page, pageSize int) ([]domain.BusCredential, int, error)
	GetBusByID(id int64) (*domain.BusCredential, error)
	UpdateBus(bus domain.BusCredential) error
	DeleteBus(id int64) error

	// Routes
	GetAllRoutes(page, pageSize int) ([]domain.Route, int, error)
	DeleteRoute(id int64) error

	// Tickets
	GetAllTickets(page, pageSize int) ([]domain.Ticket, int, error)

	// Transactions
	GetAllTransactions(page, pageSize int) ([]domain.Transaction, int, error)
}

type service struct {
	repo        repo.AdminRepo
	utilHandler *utils.Handler
}

func NewService(repo repo.AdminRepo, utilHandler *utils.Handler) Service {
	return &service{
		repo:        repo,
		utilHandler: utilHandler,
	}
}

func (s *service) Login(username, password string) (*domain.Admin, string, error) {
	admin, err := s.repo.GetByUsername(username)
	if err != nil {
		return nil, "", fmt.Errorf("invalid credentials")
	}

	if err := bcrypt.CompareHashAndPassword([]byte(admin.Password), []byte(password)); err != nil {
		return nil, "", fmt.Errorf("invalid credentials")
	}

	token, err := s.utilHandler.CreateJWT(admin)
	if err != nil {
		return nil, "", fmt.Errorf("failed to generate token: %w", err)
	}

	return admin, token, nil
}

// Users
func (s *service) GetAllUsers(page, pageSize int) ([]domain.User, int, error) {
	offset := (page - 1) * pageSize
	return s.repo.GetAllUsers(pageSize, offset)
}

func (s *service) GetUserByID(id int64) (*domain.User, error) {
	return s.repo.GetUserByID(id)
}

func (s *service) UpdateUser(user domain.User) error {
	return s.repo.UpdateUser(user)
}

func (s *service) DeleteUser(id int64) error {
	return s.repo.DeleteUser(id)
}

// Dashboard
func (s *service) GetDashboardStats() (map[string]interface{}, error) {
	return s.repo.GetDashboardStats()
}

// Bus Owners
func (s *service) GetAllBusOwners(page, pageSize int) ([]domain.BusOwner, int, error) {
	offset := (page - 1) * pageSize
	return s.repo.GetAllBusOwners(pageSize, offset)
}

func (s *service) GetBusOwnerByID(id int64) (*domain.BusOwner, error) {
	return s.repo.GetBusOwnerByID(id)
}

func (s *service) CreateBusOwner(owner domain.BusOwner) error {
	return s.repo.CreateBusOwner(owner)
}

func (s *service) UpdateBusOwner(owner domain.BusOwner) error {
	return s.repo.UpdateBusOwner(owner)
}

func (s *service) DeleteBusOwner(id int64) error {
	return s.repo.DeleteBusOwner(id)
}

// Buses
func (s *service) GetAllBuses(page, pageSize int) ([]domain.BusCredential, int, error) {
	offset := (page - 1) * pageSize
	return s.repo.GetAllBuses(pageSize, offset)
}

func (s *service) GetBusByID(id int64) (*domain.BusCredential, error) {
	return s.repo.GetBusByID(id)
}

func (s *service) UpdateBus(bus domain.BusCredential) error {
	return s.repo.UpdateBus(bus)
}

func (s *service) DeleteBus(id int64) error {
	return s.repo.DeleteBus(id)
}

// Routes
func (s *service) GetAllRoutes(page, pageSize int) ([]domain.Route, int, error) {
	offset := (page - 1) * pageSize
	return s.repo.GetAllRoutes(pageSize, offset)
}

func (s *service) DeleteRoute(id int64) error {
	return s.repo.DeleteRoute(id)
}

// Tickets
func (s *service) GetAllTickets(page, pageSize int) ([]domain.Ticket, int, error) {
	offset := (page - 1) * pageSize
	return s.repo.GetAllTickets(pageSize, offset)
}

// Transactions
func (s *service) GetAllTransactions(page, pageSize int) ([]domain.Transaction, int, error) {
	offset := (page - 1) * pageSize
	return s.repo.GetAllTransactions(pageSize, offset)
}
