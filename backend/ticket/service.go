package ticket

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"strconv"
	"swift_transit/infra/payment"
	"swift_transit/infra/rabbitmq"
	"swift_transit/user"
	"time"

	"github.com/go-pdf/fpdf"
	"github.com/go-redis/redis/v8"
	"github.com/google/uuid"
	amqp "github.com/rabbitmq/amqp091-go"
	"github.com/skip2/go-qrcode"
)

type service struct {
	repo       TicketRepo
	userRepo   user.UserRepo
	redis      *redis.Client
	sslCommerz *payment.SSLCommerz
	rabbitMQ   *rabbitmq.RabbitMQ
	ctx        context.Context
}

func NewService(repo TicketRepo, userRepo user.UserRepo, redis *redis.Client, sslCommerz *payment.SSLCommerz, rabbitMQ *rabbitmq.RabbitMQ, ctx context.Context) Service {
	return &service{
		repo:       repo,
		userRepo:   userRepo,
		redis:      redis,
		sslCommerz: sslCommerz,
		rabbitMQ:   rabbitMQ,
		ctx:        ctx,
	}
}

func (s *service) BuyTicket(req BuyTicketRequest) (*BuyTicketResponse, error) {
	// 1. Validate request (basic validation)
	if req.UserId == 0 || req.RouteId == 0 {
		return nil, fmt.Errorf("invalid request")
	}

	// 2. Calculate Fare
	fare, err := s.repo.CalculateFare(req.RouteId, req.StartDestination, req.EndDestination)
	if err != nil {
		return nil, fmt.Errorf("failed to calculate fare: %w", err)
	}

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

	if val == "processing" {
		return &BuyTicketResponse{
			Message: "Processing",
		}, nil
	}

	// If it's a URL (success)
	return &BuyTicketResponse{
		PaymentURL: val,
		Message:    "Ready",
	}, nil
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

	return true, nil
}

func (s *service) UpdatePaymentStatus(id int64) error {
	return s.repo.UpdateStatus(id, true)
}

func (s *service) DownloadTicket(id int64) ([]byte, error) {
	// Fetch ticket
	ticket, err := s.repo.Get(id)
	if err != nil {
		return nil, fmt.Errorf("failed to get ticket: %w", err)
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
