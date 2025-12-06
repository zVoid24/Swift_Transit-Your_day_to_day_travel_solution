package ticket

import (
	"fmt"
	"math"
	"swift_transit/domain"
	"swift_transit/model"
	"time"

	"github.com/google/uuid"
)

func (s *service) ProcessRFIDPayment(req RFIDPaymentRequest) (*RFIDPaymentResponse, error) {
	// 1. Find User by RFID
	user, err := s.userRepo.FindByRFID(req.RFID)
	if err != nil {
		return nil, fmt.Errorf("invalid RFID card")
	}

	// Check if RFID is active
	if !user.IsRFIDActive {
		return &RFIDPaymentResponse{
			Success: false,
			Status:  "INACTIVE",
			Message: "RFID card is inactive",
			Balance: float64(user.Balance),
			Fare:    0,
		}, nil
	}

	// Check for double deduction (ticket within last 5 minutes)
	latestTicket, err := s.repo.GetLatestTicket(user.Id, req.RouteID)
	if err == nil && latestTicket != nil {
		createdAt, parseErr := time.Parse(time.RFC3339, latestTicket.CreatedAt)
		if parseErr == nil {
			if time.Since(createdAt) < 5*time.Minute && latestTicket.BusName == req.BusName {
				return &RFIDPaymentResponse{
					Success:  true,
					Status:   "DUPLICATE",
					Message:  "Already paid (recent ticket)",
					Balance:  float64(user.Balance),
					Fare:     latestTicket.Fare,
					TicketID: latestTicket.Id,
				}, nil
			}
		}
	}

	// 2. Calculate Fare
	fare, err := s.repo.CalculateFare(req.RouteID, req.StartDestination, req.EndDestination)
	if err != nil {
		return nil, fmt.Errorf("failed to calculate fare: %w", err)
	}
	fare = math.Ceil(fare) // Ensure whole number

	// 3. Check Balance
	if float64(user.Balance) < fare {
		return &RFIDPaymentResponse{
			Success: false,
			Status:  "INSUFFICIENT_BALANCE",
			Message: "Insufficient balance",
			Balance: float64(user.Balance),
			Fare:    fare,
		}, nil
	}

	// 4. Deduct Balance
	if err := s.userRepo.DeductBalance(user.Id, fare); err != nil {
		return nil, fmt.Errorf("failed to deduct balance: %w", err)
	}

	// 5. Create Ticket (Paid and Checked)
	batchID := uuid.New().String()
	ticket := domain.Ticket{
		UserId:           user.Id,
		RouteId:          req.RouteID,
		BusName:          req.BusName,
		StartDestination: req.StartDestination,
		EndDestination:   req.EndDestination,
		Fare:             fare,
		PaymentStatus:    "paid",
		PaidStatus:       true,
		PaymentMethod:    "RFID",
		BatchID:          batchID,
		QRCode:           fmt.Sprintf("TICKET-%d-%s", time.Now().UnixNano(), uuid.New().String()), // Temporary ID part
		CreatedAt:        time.Now().Format(time.RFC3339),
		Checked:          true, // Immediately marked as checked/used
	}

	createdTicket, err := s.repo.Create(ticket)
	if err != nil {
		// Refund if ticket creation fails
		s.userRepo.CreditBalance(user.Id, fare)
		return nil, fmt.Errorf("failed to create ticket: %w", err)
	}

	// 6. Create Transaction
	s.CreateTransaction(model.Transaction{
		UserID:        int(user.Id),
		Amount:        fare,
		Type:          "purchase",
		Description:   fmt.Sprintf("RFID Trip - %s", req.BusName),
		PaymentMethod: "RFID",
		CreatedAt:     time.Now(),
	})

	return &RFIDPaymentResponse{
		Success:  true,
		Status:   "SUCCESS",
		Message:  "Payment successful",
		Balance:  float64(user.Balance) - fare,
		Fare:     fare,
		TicketID: createdTicket.Id,
	}, nil
}
