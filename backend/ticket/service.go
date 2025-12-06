package ticket

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"math"
	"strconv"
	"strings"
	"swift_transit/domain"
	"swift_transit/infra/payment"
	"swift_transit/infra/rabbitmq"
	"swift_transit/model"
	"swift_transit/user"
	"time"

	"github.com/go-pdf/fpdf"
	"github.com/go-redis/redis/v8"
	"github.com/google/uuid"
	amqp "github.com/rabbitmq/amqp091-go"
	"github.com/skip2/go-qrcode"
)

type TransactionRepo interface {
	Create(t model.Transaction) error
}

type service struct {
	repo            TicketRepo
	userRepo        user.UserRepo
	transactionRepo TransactionRepo
	redis           *redis.Client
	sslCommerz      *payment.SSLCommerz
	rabbitMQ        *rabbitmq.RabbitMQ
	ctx             context.Context
	publicBaseURL   string
}

func NewService(repo TicketRepo, userRepo user.UserRepo, transactionRepo TransactionRepo, redis *redis.Client, sslCommerz *payment.SSLCommerz, rabbitMQ *rabbitmq.RabbitMQ, ctx context.Context, publicBaseURL string) Service {
	return &service{
		repo:            repo,
		userRepo:        userRepo,
		transactionRepo: transactionRepo,
		redis:           redis,
		sslCommerz:      sslCommerz,
		rabbitMQ:        rabbitMQ,
		ctx:             ctx,
		publicBaseURL:   strings.TrimRight(publicBaseURL, "/"),
	}
}

func (s *service) BuyTicket(req BuyTicketRequest) (*BuyTicketResponse, error) {
	// 1. Validate request (basic validation)
	if req.UserId == 0 || req.RouteId == 0 {
		return nil, fmt.Errorf("invalid request")
	}

	if req.Quantity == 0 {
		req.Quantity = 1
	}

	if req.Quantity < 1 || req.Quantity > 4 {
		return nil, fmt.Errorf("you can purchase between 1 and 4 tickets per request")
	}

	// 2. Calculate Fare
	fare, err := s.repo.CalculateFare(req.RouteId, req.StartDestination, req.EndDestination)
	if err != nil {
		return nil, fmt.Errorf("failed to calculate fare: %w", err)
	}

	existing, err := s.repo.CountActiveTicketsByRoute(req.UserId, req.RouteId)
	if err != nil {
		return nil, fmt.Errorf("failed to check existing tickets: %w", err)
	}

	if existing >= 4 {
		return nil, fmt.Errorf("ticket limit reached for this route (max 4 active tickets)")
	}

	remaining := 4 - existing
	if req.Quantity > remaining {
		return nil, fmt.Errorf("you already have %d active ticket(s) on this route. You can buy up to %d more for this route", existing, remaining)
	}

	batchID := uuid.New().String()
	totalFare := fare * float64(req.Quantity)

	// 3. Create a temporary ID or use a UUID for tracking the request
	// For simplicity, we might need to generate an ID here or let the worker handle it.
	// However, to return a status, we need an ID.
	// Let's generate a temporary ID or use Redis to store the initial "Processing" state.
	// Actually, we can just return a message saying "Processing" and maybe a tracking ID.
	// But the user wants to poll.
	// Let's generate a UUID for the tracking ID.
	trackingID := uuid.New().String()

	// 4. Publish to RabbitMQ
	msg := TicketRequestMessage{
		UserId:           req.UserId,
		RouteId:          req.RouteId,
		BusName:          req.BusName,
		StartDestination: req.StartDestination,
		EndDestination:   req.EndDestination,
		Fare:             fare,
		TotalFare:        totalFare,
		Quantity:         req.Quantity,
		BatchID:          batchID,
		PaymentMethod:    req.PaymentMethod,
	}
	reqJSON, err := json.Marshal(msg)
	if err != nil {
		return nil, err
	}

	q, err := s.rabbitMQ.DeclareQueue("ticket_queue")
	if err != nil {
		return nil, err
	}

	err = s.rabbitMQ.Channel.Publish(
		"",     // exchange
		q.Name, // routing key
		false,  // mandatory
		false,  // immediate
		amqp.Publishing{
			ContentType: "application/json",
			Body:        reqJSON,
			Headers: amqp.Table{
				"tracking_id": trackingID,
			},
		})
	if err != nil {
		return nil, err
	}

	// 4. Store initial status in Redis
	s.redis.Set(s.ctx, fmt.Sprintf("ticket_status:%s", trackingID), "processing", 1*time.Hour)

	return &BuyTicketResponse{
		Message:     "Ticket request received. Processing...",
		PaymentURL:  "", // Will be available later
		DownloadURL: "",
		TrackingID:  trackingID,
	}, nil
}

func (s *service) GetTicketStatus(trackingID string) (*BuyTicketResponse, error) {
	// Check Redis for status
	val, err := s.redis.Get(s.ctx, fmt.Sprintf("ticket_status:%s", trackingID)).Result()
	if err == redis.Nil {
		return nil, fmt.Errorf("request not found")
	} else if err != nil {
		return nil, err
	}

	// Try to parse as JSON
	var statusData map[string]interface{}
	if err := json.Unmarshal([]byte(val), &statusData); err == nil {
		status, _ := statusData["status"].(string)
		url, _ := statusData["url"].(string)

		var ticketID int64
		if tid, ok := statusData["ticket_id"].(float64); ok {
			ticketID = int64(tid)
		}

		var ticketIDs []int64
		if ids, ok := statusData["ticket_ids"].([]interface{}); ok {
			for _, raw := range ids {
				if val, ok := raw.(float64); ok {
					ticketIDs = append(ticketIDs, int64(val))
				}
			}
		}

		resp := &BuyTicketResponse{
			Message: status,
		}

		if ticketID != 0 {
			fullTicket, err := s.repo.Get(ticketID)
			if err == nil {
				resp.Ticket = fullTicket
			} else {
				// Fallback if DB fetch fails (shouldn't happen usually)
				resp.Ticket = &domain.Ticket{Id: ticketID}
			}
		}

		if len(ticketIDs) > 0 {
			resp.TicketIDs = ticketIDs
		}

		if status == "ready" {
			resp.PaymentURL = url
			resp.Message = "Ready"
		} else if status == "paid" {
			resp.DownloadURL = url
			resp.Message = "Paid"
		} else if status == "failed" {
			resp.Message = "Failed"
			if errMsg, ok := statusData["error"].(string); ok {
				resp.Message = fmt.Sprintf("Failed: %s", errMsg)
			}
		} else {
			resp.Message = "Processing"
		}

		return resp, nil
	}

	// Fallback for old string format (if any) or simple processing state
	if val == "processing" {
		return &BuyTicketResponse{
			Message: "Processing",
		}, nil
	}

	// If it's a URL (success) - legacy fallback
	return &BuyTicketResponse{
		PaymentURL: val,
		Message:    "Ready",
	}, nil
}

func (s *service) GetPaymentStatus(ticketID int64) (string, error) {
	ticket, err := s.repo.Get(ticketID)
	if err != nil {
		return "", err
	}
	if ticket.CancelledAt != nil {
		return "cancelled", nil
	}
	if ticket.PaymentStatus != "" {
		if ticket.PaymentStatus == "paid" {
			return "paid", nil
		}
		if ticket.PaymentUsed && ticket.PaymentStatus != "paid" {
			return "failed", nil
		}
		return ticket.PaymentStatus, nil
	}
	if ticket.PaidStatus {
		return "paid", nil
	}
	return "unpaid", nil
}

func (s *service) ValidatePayment(valID string, tranID string, amount float64) (bool, error) {
	// 1. Call SSLCommerz Validation API
	resp, err := s.sslCommerz.ValidateTransaction(valID)
	if err != nil {
		return false, fmt.Errorf("validation api failed: %w", err)
	}

	// 2. Check status
	if resp.Status != "VALID" && resp.Status != "VALIDATED" {
		return false, fmt.Errorf("invalid transaction status: %s", resp.Status)
	}

	// 3. Verify Amount (Parse string to float)
	respAmount, err := strconv.ParseFloat(resp.Amount, 64)
	if err != nil {
		return false, fmt.Errorf("invalid amount format from api: %w", err)
	}

	if respAmount != amount {
		return false, fmt.Errorf("amount mismatch: expected %.2f, got %.2f", amount, respAmount)
	}

	// 4. Update Payment Status in DB
	// Extract Ticket ID from tranID (Format: TICKET-{ID}-{UUID})
	var ticketID int64
	_, err = fmt.Sscanf(tranID, "TICKET-%d-", &ticketID)
	if err != nil {
		return false, fmt.Errorf("failed to extract ticket id from tran_id: %w", err)
	}

	if err := s.UpdatePaymentStatus(ticketID); err != nil {
		return false, fmt.Errorf("failed to update payment status in db: %w", err)
	}

	// 5. Store valid ticket in Redis for 4 hours
	ticket, err := s.repo.Get(ticketID)
	if err == nil {
		validTicket := map[string]interface{}{
			"ticket_id":         ticket.Id,
			"route_id":          ticket.RouteId,
			"start_destination": ticket.StartDestination,
			"end_destination":   ticket.EndDestination,
			"user_id":           ticket.UserId,
			"created_at":        ticket.CreatedAt,
			"checked":           false,
		}
		validTicketJSON, _ := json.Marshal(validTicket)
		s.redis.Set(s.ctx, fmt.Sprintf("ticket_valid:%s", ticket.QRCode), validTicketJSON, 4*time.Hour)
	}

	return true, nil
}

func (s *service) CheckTicket(req CheckTicketRequest) (map[string]interface{}, error) {
	// 1. Check Redis
	val, err := s.redis.Get(s.ctx, fmt.Sprintf("ticket_valid:%s", req.QRCode)).Result()
	if err == redis.Nil {
		return map[string]interface{}{
			"success": false,
			"status":  "invalid",
			"message": "Invalid or expired ticket",
		}, nil
	} else if err != nil {
		return nil, err
	}

	var ticketData map[string]interface{}
	if err := json.Unmarshal([]byte(val), &ticketData); err != nil {
		return nil, fmt.Errorf("failed to parse ticket data")
	}

	// 2. Validate Route
	tRouteID := int64(ticketData["route_id"].(float64))
	if tRouteID != req.RouteID {
		return map[string]interface{}{
			"success": false,
			"status":  "invalid_route",
			"message": "Ticket is not for this route",
		}, nil
	}

	// 3. Check if already checked
	if checked, ok := ticketData["checked"].(bool); ok && checked {
		return map[string]interface{}{
			"success":   false,
			"status":    "already_used",
			"message":   "Ticket already used",
			"ticket_id": ticketData["ticket_id"],
		}, nil
	}

	// 4. Check for Over-travel (Extra Fare)
	endDest, ok := ticketData["end_destination"].(string)
	if !ok {
		return nil, fmt.Errorf("invalid ticket data: missing end_destination")
	}

	destStop, err := s.repo.GetStop(req.RouteID, endDest)
	if err != nil {
		return nil, fmt.Errorf("failed to verify destination stop: %v", err)
	}

	var response map[string]interface{}
	if req.CurrentStoppage.Order > destStop.Order {
		// Calculate Extra Fare
		extraFare, err := s.repo.CalculateFare(req.RouteID, endDest, req.CurrentStoppage.Name)
		if err != nil {
			return nil, fmt.Errorf("failed to calculate extra fare: %v", err)
		}

		response = map[string]interface{}{
			"success":          false, // Not fully successful until extra fare is handled
			"status":           "over_travel",
			"message":          fmt.Sprintf("Over-travel detected. Pay extra: %.2f", extraFare),
			"extra_fare":       extraFare,
			"current_stoppage": req.CurrentStoppage.Name,
			"ticket_end":       endDest,
			"ticket_id":        ticketData["ticket_id"],
			"checked":          true,
		}
	} else {
		response = ticketData
		response["success"] = true
		response["status"] = "valid"
		response["message"] = "Ticket Valid"
		response["checked"] = true
	}

	// 5. Mark as checked in Redis
	ticketData["checked"] = true
	updatedJSON, _ := json.Marshal(ticketData)
	s.redis.Set(s.ctx, fmt.Sprintf("ticket_valid:%s", req.QRCode), updatedJSON, redis.KeepTTL)

	// 6. Publish to RabbitMQ for async updates (DB update)
	checkEvent := map[string]interface{}{
		"ticket_id":        ticketData["ticket_id"],
		"qr_code":          req.QRCode,
		"current_stoppage": req.CurrentStoppage.Name,
		"checked_at":       time.Now(),
	}
	eventJSON, _ := json.Marshal(checkEvent)

	q, err := s.rabbitMQ.DeclareQueue("ticket_check_queue")
	if err == nil {
		s.rabbitMQ.Channel.Publish(
			"",     // exchange
			q.Name, // routing key
			false,  // mandatory
			false,  // immediate
			amqp.Publishing{
				ContentType: "application/json",
				Body:        eventJSON,
			})
	}

	return response, nil
}

func (s *service) CreateOverTravelTicket(originalTicketID int64, currentStop string, paymentCollected bool) (*domain.Ticket, error) {
	originalTicket, err := s.repo.Get(originalTicketID)
	if err != nil {
		return nil, fmt.Errorf("original ticket not found: %w", err)
	}

	fare, err := s.repo.CalculateFare(originalTicket.RouteId, originalTicket.EndDestination, currentStop)
	if err != nil {
		return nil, fmt.Errorf("failed to calculate fare: %w", err)
	}
	fare = math.Ceil(fare)

	batchID := uuid.New().String()
	newTicket := domain.Ticket{
		UserId:           originalTicket.UserId,
		RouteId:          originalTicket.RouteId,
		BusName:          originalTicket.BusName,
		StartDestination: originalTicket.EndDestination,
		EndDestination:   currentStop,
		Fare:             fare,
		PaymentStatus:    "unpaid",
		PaidStatus:       false,
		PaymentMethod:    "CASH", // Assumed cash for over-travel
		BatchID:          batchID,
		QRCode:           fmt.Sprintf("OT-%d-%s", time.Now().UnixNano(), uuid.New().String()),
		CreatedAt:        time.Now().Format(time.RFC3339),
		Checked:          true, // Auto-checked
	}

	if paymentCollected {
		newTicket.PaymentStatus = "paid"
		newTicket.PaidStatus = true
	}

	createdTicket, err := s.repo.Create(newTicket)
	if err != nil {
		return nil, fmt.Errorf("failed to create ticket: %w", err)
	}

	// Create Transaction if paid
	if paymentCollected {
		s.CreateTransaction(model.Transaction{
			UserID:        int(originalTicket.UserId),
			Amount:        fare,
			Type:          "purchase",
			Description:   fmt.Sprintf("Over-Travel Ticket - %s", originalTicket.BusName),
			PaymentMethod: "CASH",
			CreatedAt:     time.Now(),
		})
	}

	return createdTicket, nil
}

func (s *service) ValidateTicket(id int64) error {
	ticket, err := s.repo.Get(id)
	if err != nil {
		return err
	}
	if ticket.CancelledAt != nil {
		return fmt.Errorf("ticket has been cancelled")
	}
	return s.repo.ValidateTicket(id)
}

func (s *service) CreateTransaction(t model.Transaction) error {
	return s.transactionRepo.Create(t)
}

func (s *service) UpdatePaymentStatus(id int64) error {
	ticket, err := s.repo.Get(id)
	if err != nil {
		return err
	}
	if ticket.PaymentUsed {
		if ticket.PaidStatus {
			return nil
		}
		return fmt.Errorf("payment link already used")
	}

	if err := s.repo.UpdateBatchPaymentStatus(ticket.BatchID, true, "paid", true); err != nil {
		return err
	}

	// Calculate total amount for the batch
	count, err := s.repo.GetBatchCount(ticket.BatchID)
	if err != nil {
		// Fallback to 1 if count fails, though it shouldn't
		count = 1
	}

	totalAmount := ticket.Fare * float64(count)

	// Create Transaction
	return s.CreateTransaction(model.Transaction{
		UserID:        int(ticket.UserId),
		Amount:        totalAmount,
		Type:          "purchase",
		Description:   fmt.Sprintf("Ticket Purchase - %s (x%d)", ticket.BusName, count),
		PaymentMethod: "Online", // Or "Gateway"
		CreatedAt:     time.Now(),
	})
}

func (s *service) HandlePaymentResult(id int64, status string) (bool, error) {
	ticket, err := s.repo.Get(id)
	if err != nil {
		return false, err
	}

	if ticket.PaymentUsed {
		return true, nil
	}

	paid := status == "paid"
	if err := s.repo.UpdateBatchPaymentStatus(ticket.BatchID, paid, status, true); err != nil {
		return false, err
	}

	return false, nil
}

func (s *service) DownloadTicket(id int64) ([]byte, error) {
	// Fetch ticket
	ticket, err := s.repo.Get(id)
	if err != nil {
		return nil, fmt.Errorf("failed to get ticket: %w", err)
	}

	if ticket.CancelledAt != nil {
		return nil, fmt.Errorf("ticket has been cancelled")
	}

	if !ticket.PaidStatus {
		return nil, fmt.Errorf("ticket is unpaid")
	}

	// Generate QR Code
	qrCode, err := qrcode.Encode(ticket.QRCode, qrcode.Medium, 256)
	if err != nil {
		return nil, fmt.Errorf("failed to generate QR code: %w", err)
	}

	// Create PDF
	pdf := fpdf.New("P", "mm", "A4", "")
	pdf.AddPage()
	pdf.SetFont("Arial", "B", 16)
	pdf.Cell(40, 10, "Swift Transit Ticket")
	pdf.Ln(12)

	pdf.SetFont("Arial", "", 12)
	pdf.Cell(40, 10, fmt.Sprintf("Ticket ID: %d", ticket.Id))
	pdf.Ln(8)
	pdf.Cell(40, 10, fmt.Sprintf("Bus Name: %s", ticket.BusName))
	pdf.Ln(8)
	pdf.Cell(40, 10, fmt.Sprintf("Route ID: %d", ticket.RouteId))
	pdf.Ln(8)
	pdf.Cell(40, 10, fmt.Sprintf("From: %s", ticket.StartDestination))
	pdf.Ln(8)
	pdf.Cell(40, 10, fmt.Sprintf("To: %s", ticket.EndDestination))
	pdf.Ln(8)
	pdf.Cell(40, 10, fmt.Sprintf("Fare: %.2f", ticket.Fare))
	pdf.Ln(8)
	pdf.Cell(40, 10, fmt.Sprintf("Date: %s", ticket.CreatedAt))
	pdf.Ln(20)

	// Embed QR Code
	// fpdf requires an image reader or file. We can use RegisterImageOptionsReader
	imageOptions := fpdf.ImageOptions{
		ImageType: "PNG",
		ReadDpi:   true,
	}
	pdf.RegisterImageOptionsReader("qrcode.png", imageOptions, bytes.NewReader(qrCode))
	pdf.ImageOptions("qrcode.png", 10, 100, 50, 50, false, imageOptions, 0, "")

	// Output to bytes
	var buf bytes.Buffer
	err = pdf.Output(&buf)
	if err != nil {
		return nil, fmt.Errorf("failed to generate PDF: %w", err)
	}

	return buf.Bytes(), nil
}

func (s *service) GetByUserID(userId int64, limit, offset int) ([]domain.Ticket, int, error) {
	tickets, total, err := s.repo.GetByUserID(userId, limit, offset)
	if err != nil {
		return nil, 0, err
	}
	for i := range tickets {
		tickets[i].Fare = math.Ceil(tickets[i].Fare)
	}
	return tickets, total, nil
}

func (s *service) CancelTicket(userID int64, ticketID int64) (float64, error) {
	ticket, err := s.repo.Get(ticketID)
	if err != nil {
		return 0, err
	}

	if ticket.UserId != userID {
		return 0, fmt.Errorf("unauthorized")
	}

	if ticket.CancelledAt != nil {
		return 0, fmt.Errorf("ticket already cancelled")
	}

	if ticket.Checked {
		return 0, fmt.Errorf("ticket already used")
	}

	if !ticket.PaidStatus {
		return 0, fmt.Errorf("unpaid tickets cannot be cancelled")
	}

	parsedTime, err := time.Parse(time.RFC3339, ticket.CreatedAt)
	if err != nil {
		parsedTime, _ = time.Parse("2006-01-02 15:04:05", ticket.CreatedAt)
	}

	if !parsedTime.IsZero() {
		if time.Since(parsedTime) > 24*time.Hour {
			return 0, fmt.Errorf("cancellation window (24h) has expired")
		}
	}

	refundAmount := ticket.Fare * 0.75

	if err := s.repo.CancelTicket(ticketID, time.Now(), "cancelled"); err != nil {
		return 0, err
	}

	if ticket.PaymentMethod == "wallet" {
		if err := s.userRepo.CreditBalance(ticket.UserId, refundAmount); err != nil {
			return 0, err
		}

		// Create Transaction for Refund
		if err := s.CreateTransaction(model.Transaction{
			UserID:        int(ticket.UserId),
			Amount:        refundAmount,
			Type:          "refund",
			Description:   fmt.Sprintf("Ticket Refund - %s", ticket.BusName),
			PaymentMethod: "Wallet",
			CreatedAt:     time.Now(),
		}); err != nil {
			// Log error but don't fail the request as refund is already processed
			fmt.Printf("failed to create refund transaction: %v\n", err)
		}
	}

	return refundAmount, nil
}
