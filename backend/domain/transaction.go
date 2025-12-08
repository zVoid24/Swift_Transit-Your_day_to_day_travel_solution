package domain

import "time"

type Transaction struct {
	ID            int64     `json:"id"`
	UserID        int64     `json:"user_id"`
	Amount        float64   `json:"amount"`
	Type          string    `json:"type"` // credit, debit, purchase, refund
	Description   string    `json:"description"`
	PaymentMethod string    `json:"payment_method"`
	CreatedAt     time.Time `json:"created_at"`
}
