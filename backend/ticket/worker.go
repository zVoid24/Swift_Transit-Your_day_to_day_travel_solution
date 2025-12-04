package ticket

import (
	"encoding/json"
	"fmt"
	"log"
	"time"

	"swift_transit/domain"
	"swift_transit/infra/rabbitmq"

	"github.com/google/uuid"
)

type TicketWorker struct {
	svc      Service
	rabbitMQ *rabbitmq.RabbitMQ
}

func NewTicketWorker(svc Service, rabbitMQ *rabbitmq.RabbitMQ) *TicketWorker {
	return &TicketWorker{
		svc:      svc,
		rabbitMQ: rabbitMQ,
	}
}

func (w *TicketWorker) Start() {
	q, err := w.rabbitMQ.DeclareQueue("ticket_queue")
	if err != nil {
		log.Fatalf("Failed to declare queue: %v", err)
	}

	msgs, err := w.rabbitMQ.Channel.Consume(
		q.Name, // queue
		"",     // consumer
		true,   // auto-ack
		false,  // exclusive
		false,  // no-local
		false,  // no-wait
		nil,    // args
	)
	if err != nil {
		log.Fatalf("Failed to register a consumer: %v", err)
	}

	forever := make(chan bool)

	go func() {
		for d := range msgs {
			log.Printf("Received a message: %s", d.Body)

			var req TicketRequestMessage
			err := json.Unmarshal(d.Body, &req)
			if err != nil {
				log.Printf("Error decoding JSON: %s", err)
				continue
			}

			trackingID := ""
			if val, ok := d.Headers["tracking_id"]; ok {
				trackingID = val.(string)
			}

			w.ProcessTicket(req, trackingID)
		}
	}()

	log.Printf(" [*] Waiting for messages. To exit press CTRL+C")
	<-forever
}

func (w *TicketWorker) ProcessTicket(req TicketRequestMessage, trackingID string) {
	// This logic is similar to the original BuyTicket but adapted for background processing
	// We need to access the service's internal dependencies, but since we are in the same package,
	// we can cast the interface to the struct if needed, or better, expose a method on the service
	// to handle the actual processing.
	// However, `Service` interface doesn't have `ProcessTicket`.
	// Let's implement the logic here using the service methods where possible,
	// but wait, `BuyTicket` in service is now the producer.
	// We need the logic that WAS in `BuyTicket` (DB insert, Payment Init).

	// Since `TicketWorker` is in `ticket` package, it can access `service` struct fields if we pass `*service` instead of `Service` interface.
	// Or we can add a `ProcessTicketInternal` method to `Service` interface (not ideal for public API).
	// Or we can just duplicate the logic/move it to a helper in `service.go`.

	// Let's cast the service to `*service` to access dependencies.
	s, ok := w.svc.(*service)
	if !ok {
		log.Printf("Service is not of type *service")
		return
	}

	baseURL := s.publicBaseURL

	qrCode := uuid.New().String()
	now := time.Now().Format(time.RFC3339)

	ticket := domain.Ticket{
		UserId:           req.UserId,
		RouteId:          req.RouteId,
		BusName:          req.BusName,
		StartDestination: req.StartDestination,
		EndDestination:   req.EndDestination,
		Fare:             req.Fare,
		QRCode:           qrCode,
		CreatedAt:        now,
	}

	if req.PaymentMethod == "wallet" {
		// Deduct balance
		err := s.userRepo.DeductBalance(req.UserId, req.Fare)
		if err != nil {
			log.Printf("Payment failed: %v", err)
			// Update status to failed
			s.redis.Set(s.ctx, fmt.Sprintf("ticket_status:%s", trackingID), "failed", 1*time.Hour)
			return
		}
		ticket.PaidStatus = true
	} else {
		ticket.PaidStatus = false
	}

	// Create ticket in DB
	createdTicket, err := s.repo.Create(ticket)
	if err != nil {
		log.Printf("Failed to create ticket: %v", err)
		s.redis.Set(s.ctx, fmt.Sprintf("ticket_status:%s", trackingID), "failed", 1*time.Hour)
		return
	}

	if req.PaymentMethod == "wallet" {
		// Store in Redis (valid for 5 hours)
		ticketJSON, _ := json.Marshal(createdTicket)
		key := fmt.Sprintf("ticket:%d", createdTicket.Id)
		err = s.redis.Set(s.ctx, key, ticketJSON, 5*time.Hour).Err()
		if err != nil {
			log.Printf("Failed to cache ticket: %v", err)
		}

		// Update status to success (maybe return ticket ID or something)
		// For wallet, there is no payment URL, so maybe we return a special URL or just "Success"
		// The client expects a URL or "Ready".
		// Let's store a success message or a dummy URL.
		s.redis.Set(s.ctx, fmt.Sprintf("ticket_status:%s", trackingID), fmt.Sprintf("/ticket/download?id=%d", createdTicket.Id), 1*time.Hour)

	} else {
		// Init SSLCommerz
		tranID := fmt.Sprintf("TICKET-%d-%s", createdTicket.Id, uuid.New().String()[:8])
		successUrl := fmt.Sprintf("%s/ticket/payment/success?id=%d", baseURL, createdTicket.Id)
		failUrl := fmt.Sprintf("%s/ticket/payment/fail", baseURL)
		cancelUrl := fmt.Sprintf("%s/ticket/payment/cancel", baseURL)

		gatewayUrl, err := s.sslCommerz.InitPayment(req.Fare, tranID, successUrl, failUrl, cancelUrl)
		if err != nil {
			log.Printf("Gateway init failed: %v", err)
			s.redis.Set(s.ctx, fmt.Sprintf("ticket_status:%s", trackingID), "failed", 1*time.Hour)
			return
		}

		// Update status with Gateway URL
		s.redis.Set(s.ctx, fmt.Sprintf("ticket_status:%s", trackingID), gatewayUrl, 1*time.Hour)
	}
}
