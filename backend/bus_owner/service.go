package bus_owner

import (
	"fmt"
	"swift_transit/domain"
	"swift_transit/repo"
	"swift_transit/utils"

	"golang.org/x/crypto/bcrypt"
)

type Service interface {
	Register(username, password string) error
	Login(username, password string) (*domain.BusOwner, string, error)
	RegisterBus(ownerId int64, regNo, password string, routeIdUp, routeIdDown int64) error
	GetBuses(ownerId int64) ([]domain.BusCredential, error)
	GetAnalytics(ownerId int64) (map[string]interface{}, error)
	GetPerBusAnalytics(ownerId int64) ([]domain.BusAnalytics, error)
	GetRoutes() ([]domain.Route, error)
}

type service struct {
	repo        repo.BusOwnerRepo
	busRepo     repo.BusRepo
	ticketRepo  repo.TicketRepo
	routeRepo   repo.RouteRepo
	utilHandler *utils.Handler
}

func NewService(repo repo.BusOwnerRepo, busRepo repo.BusRepo, ticketRepo repo.TicketRepo, routeRepo repo.RouteRepo, utilHandler *utils.Handler) Service {
	return &service{
		repo:        repo,
		busRepo:     busRepo,
		ticketRepo:  ticketRepo,
		routeRepo:   routeRepo,
		utilHandler: utilHandler,
	}
}

func (s *service) Register(username, password string) error {
	hashedPassword, err := bcrypt.GenerateFromPassword([]byte(password), bcrypt.DefaultCost)
	if err != nil {
		return fmt.Errorf("failed to hash password: %w", err)
	}

	owner := domain.BusOwner{
		Username: username,
		Password: string(hashedPassword),
	}

	return s.repo.Create(owner)
}

func (s *service) Login(username, password string) (*domain.BusOwner, string, error) {
	owner, err := s.repo.GetByUsername(username)
	if err != nil {
		return nil, "", fmt.Errorf("invalid credentials")
	}

	if err := bcrypt.CompareHashAndPassword([]byte(owner.Password), []byte(password)); err != nil {
		return nil, "", fmt.Errorf("invalid credentials")
	}

	token, err := s.utilHandler.CreateJWT(owner)
	if err != nil {
		return nil, "", fmt.Errorf("failed to generate token: %w", err)
	}

	return owner, token, nil
}

func (s *service) RegisterBus(ownerId int64, regNo, password string, routeIdUp, routeIdDown int64) error {
	// Check limit (max 10 buses per route per owner)
	// We check for both up and down routes, assuming they are the same logical route usually,
	// or we count total buses associated with either.
	// The requirement says "register bus up to 10 in each route".

	countUp, err := s.repo.CountBusesByRoute(ownerId, routeIdUp)
	if err != nil {
		return err
	}
	if countUp >= 10 {
		return fmt.Errorf("bus limit reached for route %d", routeIdUp)
	}

	if routeIdDown != routeIdUp {
		countDown, err := s.repo.CountBusesByRoute(ownerId, routeIdDown)
		if err != nil {
			return err
		}
		if countDown >= 10 {
			return fmt.Errorf("bus limit reached for route %d", routeIdDown)
		}
	}

	// Create Bus Credential
	// We need to update BusRepo to support creating with OwnerId or add a method here.
	// Since BusRepo is in another package, we might need to update it or use a new method in BusOwnerRepo?
	// Actually, BusRepo usually handles bus_credentials. Let's check BusRepo.
	// For now, let's assume we can add a method to BusRepo or use BusOwnerRepo to insert into bus_credentials.
	// Given the architecture, it's better to use BusRepo if possible, but we need to pass OwnerId.
	// Let's implement a CreateBus method in BusOwnerRepo for simplicity as it involves the owner_id.

	// Actually, let's look at repo/bus.go first.
	// I'll assume I can add CreateBusWithOwner to BusOwnerRepo for now.

	// Wait, I need to hash the bus password too? The current implementation for bus login likely compares plain text or hashed.
	// Let's check bus login logic later. Assuming plain text for now as per previous context or hashed.
	// Let's hash it to be safe or check existing bus registration.

	hashedPassword, err := bcrypt.GenerateFromPassword([]byte(password), bcrypt.DefaultCost)
	if err != nil {
		return fmt.Errorf("failed to hash password: %w", err)
	}

	return s.busRepo.CreateCredential(domain.BusCredential{
		RegistrationNumber: regNo,
		Password:           string(hashedPassword),
		RouteIdUp:          routeIdUp,
		RouteIdDown:        routeIdDown,
		OwnerId:            &ownerId,
	})
}

func (s *service) GetBuses(ownerId int64) ([]domain.BusCredential, error) {
	return s.repo.GetBusesByOwner(ownerId)
}

func (s *service) GetAnalytics(ownerId int64) (map[string]interface{}, error) {
	analytics, err := s.repo.GetAnalytics(ownerId)
	if err != nil {
		return nil, err
	}

	return map[string]interface{}{
		"total_revenue": analytics.TotalRevenue,
		"total_tickets": analytics.TotalTickets,
		"today": map[string]interface{}{
			"revenue": analytics.Today.Revenue,
			"tickets": analytics.Today.Tickets,
		},
		"weekly": map[string]interface{}{
			"revenue": analytics.Weekly.Revenue,
			"tickets": analytics.Weekly.Tickets,
		},
		"monthly": map[string]interface{}{
			"revenue": analytics.Monthly.Revenue,
			"tickets": analytics.Monthly.Tickets,
		},
	}, nil
}

func (s *service) GetRoutes() ([]domain.Route, error) {
	return s.routeRepo.FindAll()
}

func (s *service) GetPerBusAnalytics(ownerId int64) ([]domain.BusAnalytics, error) {
	return s.repo.GetPerBusAnalytics(ownerId)
}
