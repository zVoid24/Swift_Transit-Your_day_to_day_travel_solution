package bus

import (
	"fmt"
	"strings"
	"swift_transit/domain"
	"swift_transit/ticket"

	"golang.org/x/crypto/bcrypt"
)

type BusLoginResult struct {
	Credential      *domain.BusCredential
	SelectedRouteID int64
	Variant         string
}

type service struct {
	repo       BusRepo
	ticketRepo ticket.TicketRepo
}

func NewService(repo BusRepo, ticketRepo ticket.TicketRepo) Service {
	return &service{
		repo:       repo,
		ticketRepo: ticketRepo,
	}
}

func (svc *service) FindBus(start, end string) ([]domain.Bus, error) {
	return svc.repo.FindBus(start, end)
}

func (svc *service) Login(regNum, password string, variant string) (*BusLoginResult, error) {
	bus, err := svc.repo.GetBusByRegistrationNumber(regNum)
	if err != nil {
		return nil, err
	}

	err = bcrypt.CompareHashAndPassword([]byte(bus.Password), []byte(password))
	if err != nil {
		return nil, fmt.Errorf("invalid credentials")
	}

	normalizedVariant := strings.ToLower(variant)
	var routeID int64

	switch normalizedVariant {
	case "up":
		routeID = bus.RouteIdUp
	case "down":
		routeID = bus.RouteIdDown
	default:
		return nil, fmt.Errorf("invalid variant")
	}

	if routeID == 0 {
		return nil, fmt.Errorf("route not configured for selected direction")
	}

	return &BusLoginResult{Credential: bus, SelectedRouteID: routeID, Variant: normalizedVariant}, nil
}

func (svc *service) Register(regNum, password string, routeIdUp, routeIdDown int64) (*domain.BusCredential, error) {
	hashedPassword, err := bcrypt.GenerateFromPassword([]byte(password), bcrypt.DefaultCost)
	if err != nil {
		return nil, err
	}

	busCred := domain.BusCredential{
		RegistrationNumber: regNum,
		Password:           string(hashedPassword),
		RouteIdUp:          routeIdUp,
		RouteIdDown:        routeIdDown,
	}

	return svc.repo.Create(busCred)
}

func (svc *service) ValidateTicket(ticketID int64, routeID int64) error {
	// 1. Get Ticket
	ticket, err := svc.ticketRepo.Get(ticketID)
	if err != nil {
		return err
	}

	if ticket.CancelledAt != nil {
		return fmt.Errorf("ticket has been cancelled")
	}

	if !ticket.PaidStatus {
		return fmt.Errorf("ticket is unpaid")
	}

	// 2. Check if ticket belongs to the route
	if ticket.RouteId != routeID {
		return fmt.Errorf("ticket is not valid for this route")
	}

	// 3. Check if already checked
	if ticket.Checked {
		return fmt.Errorf("ticket already checked")
	}

	// 4. Update status
	return svc.ticketRepo.ValidateTicket(ticketID)
}

func (svc *service) CheckTicket(req ticket.CheckTicketRequest) (map[string]interface{}, error) {
	t, err := svc.ticketRepo.GetByQRCode(req.QRCode)
	if err != nil {
		return nil, fmt.Errorf("ticket not found")
	}

	if t.CancelledAt != nil {
		return nil, fmt.Errorf("ticket has been cancelled")
	}
	if !t.PaidStatus {
		return nil, fmt.Errorf("ticket is unpaid")
	}
	if t.RouteId != req.RouteID {
		return nil, fmt.Errorf("ticket is not valid for this route")
	}
	if t.Checked {
		return nil, fmt.Errorf("ticket already checked")
	}

	destStop, err := svc.ticketRepo.GetStop(req.RouteID, t.EndDestination)
	if err != nil {
		return nil, fmt.Errorf("invalid destination stop in ticket: %v", err)
	}

	response := map[string]interface{}{
		"status": "valid",
		"ticket": t,
	}

	if req.CurrentStoppage.Order > destStop.Order {
		extraFare, err := svc.ticketRepo.CalculateFare(req.RouteID, t.EndDestination, req.CurrentStoppage.Name)
		if err != nil {
			return nil, fmt.Errorf("failed to calculate extra fare: %v", err)
		}

		response["status"] = "over_travel"
		response["message"] = fmt.Sprintf("You have over-traveled. Please pay extra fare: %.2f", extraFare)
		response["extra_fare"] = extraFare
	}

	err = svc.ticketRepo.ValidateTicket(t.Id)
	if err != nil {
		return nil, err
	}

	return response, nil
}
