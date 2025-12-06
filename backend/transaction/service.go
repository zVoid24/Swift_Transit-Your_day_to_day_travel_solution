package transaction

import (
	"context"
	"encoding/json"
	"fmt"
	"math"
	"strconv"
	"time"

	"github.com/go-redis/redis/v8"
	"github.com/google/uuid"

	"swift_transit/infra/payment"
	"swift_transit/model"
	"swift_transit/repo"
	"swift_transit/user"
)

type Service interface {
	GetTransactions(userID int) ([]model.Transaction, error)
	InitRecharge(ctx context.Context, userID int64, amount float64) (gatewayURL string, tranID string, err error)
	CompleteRecharge(ctx context.Context, tranID, valID string) error
	CancelRecharge(ctx context.Context, tranID string) error
}

type service struct {
	repo          *repo.TransactionRepo
	userRepo      user.UserRepo
	sslCommerz    *payment.SSLCommerz
	redis         *redis.Client
	publicBaseURL string
}

func NewService(repo *repo.TransactionRepo, userRepo user.UserRepo, sslCommerz *payment.SSLCommerz, redis *redis.Client, publicBaseURL string) Service {
	return &service{
		repo:          repo,
		userRepo:      userRepo,
		sslCommerz:    sslCommerz,
		redis:         redis,
		publicBaseURL: publicBaseURL,
	}
}

func (s *service) GetTransactions(userID int) ([]model.Transaction, error) {
	trans, err := s.repo.GetByUserID(userID)
	if err != nil {
		return nil, err
	}
	for i := range trans {
		trans[i].Amount = math.Round(trans[i].Amount*100) / 100
	}
	return trans, nil
}

type rechargeSession struct {
	UserID int64   `json:"user_id"`
	Amount float64 `json:"amount"`
}

var allowedRechargeAmounts = map[float64]bool{
	50:  true,
	100: true,
	200: true,
	300: true,
	400: true,
	500: true,
}

func (s *service) InitRecharge(ctx context.Context, userID int64, amount float64) (string, string, error) {
	if !allowedRechargeAmounts[amount] {
		return "", "", fmt.Errorf("invalid amount: choose between 50 and 500")
	}

	tranID := fmt.Sprintf("RECHARGE-%d-%s", userID, uuid.NewString()[:8])
	successURL := fmt.Sprintf("%s/wallet/recharge/success?tran_id=%s", s.publicBaseURL, tranID)
	failURL := fmt.Sprintf("%s/wallet/recharge/fail?tran_id=%s", s.publicBaseURL, tranID)
	cancelURL := fmt.Sprintf("%s/wallet/recharge/cancel?tran_id=%s", s.publicBaseURL, tranID)

	gatewayURL, err := s.sslCommerz.InitPayment(amount, tranID, successURL, failURL, cancelURL)
	if err != nil {
		return "", "", err
	}

	payload := rechargeSession{UserID: userID, Amount: amount}
	data, _ := json.Marshal(payload)
	if err := s.redis.Set(ctx, s.rechargeKey(tranID), data, time.Hour).Err(); err != nil {
		return "", "", err
	}

	return gatewayURL, tranID, nil
}

func (s *service) CompleteRecharge(ctx context.Context, tranID, valID string) error {
	session, err := s.loadSession(ctx, tranID)
	if err != nil {
		return err
	}

	if err := s.validateRecharge(valID, tranID, session.Amount); err != nil {
		return err
	}

	if err := s.userRepo.CreditBalance(session.UserID, session.Amount); err != nil {
		return err
	}

	if err := s.repo.Create(model.Transaction{
		UserID:        int(session.UserID),
		Amount:        session.Amount,
		Type:          "credit",
		Description:   "Wallet recharge",
		PaymentMethod: "SSLCommerz",
		CreatedAt:     time.Now(),
	}); err != nil {
		return err
	}

	s.redis.Del(ctx, s.rechargeKey(tranID))
	return nil
}

func (s *service) CancelRecharge(ctx context.Context, tranID string) error {
	return s.redis.Del(ctx, s.rechargeKey(tranID)).Err()
}

func (s *service) validateRecharge(valID, tranID string, expectedAmount float64) error {
	resp, err := s.sslCommerz.ValidateTransaction(valID)
	if err != nil {
		return fmt.Errorf("validation failed: %w", err)
	}

	if resp.Status != "VALID" && resp.Status != "VALIDATED" {
		return fmt.Errorf("invalid transaction status: %s", resp.Status)
	}

	if resp.TranID != "" && resp.TranID != tranID {
		return fmt.Errorf("transaction mismatch")
	}

	amount, err := parseAmount(resp.Amount)
	if err != nil {
		return err
	}

	if amount != expectedAmount {
		return fmt.Errorf("amount mismatch: expected %.2f, got %.2f", expectedAmount, amount)
	}

	return nil
}

func (s *service) loadSession(ctx context.Context, tranID string) (*rechargeSession, error) {
	val, err := s.redis.Get(ctx, s.rechargeKey(tranID)).Result()
	if err != nil {
		if err == redis.Nil {
			return nil, fmt.Errorf("recharge session expired or not found")
		}
		return nil, err
	}

	var session rechargeSession
	if err := json.Unmarshal([]byte(val), &session); err != nil {
		return nil, err
	}

	return &session, nil
}

func (s *service) rechargeKey(tranID string) string {
	return fmt.Sprintf("recharge:%s", tranID)
}

func parseAmount(amountStr string) (float64, error) {
	return strconv.ParseFloat(amountStr, 64)
}
