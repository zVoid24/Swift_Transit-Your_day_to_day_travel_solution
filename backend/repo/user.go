package repo

import (
	"context"
	"fmt"
	"swift_transit/domain"
	"swift_transit/user"
	"swift_transit/utils"

	"github.com/jmoiron/sqlx"
	"golang.org/x/crypto/bcrypt"
)

// UserRepo interface
type UserRepo interface {
	user.UserRepo
}

// userRepo struct
type userRepo struct {
	dbCon       *sqlx.DB
	utilHandler *utils.Handler
}

// Constructor
func NewUserRepo(dbCon *sqlx.DB, utilHandler *utils.Handler) UserRepo {
	return &userRepo{
		dbCon:       dbCon,
		utilHandler: utilHandler,
	}
}

func (r *userRepo) Info(ctx context.Context) (*domain.User, error) {
	// Extract the user data from context
	userData := r.utilHandler.GetUserFromContext(ctx)

	// Assert it’s a map[string]interface{} (how JSON was unmarshaled)
	dataMap, ok := userData.(map[string]interface{})
	if !ok {
		return nil, fmt.Errorf("invalid user data format")
	}

	// Convert map fields into domain.User
	user := &domain.User{
		Id:        int64(dataMap["id"].(float64)), // JSON numbers become float64
		Name:      dataMap["name"].(string),
		UserName:  dataMap["username"].(string),
		Email:     dataMap["email"].(string),
		IsStudent: dataMap["is_student"].(bool),
		Balance:   float32(dataMap["balance"].(float64)), // convert float64 → float32
	}

	return user, nil
}

// Create new user with hashed password
func (r *userRepo) Create(user domain.User) (*domain.User, error) {
	// Hash the password
	hashedPassword, err := bcrypt.GenerateFromPassword([]byte(user.Password), bcrypt.DefaultCost)
	if err != nil {
		return nil, err
	}

	query := `
		INSERT INTO users (name, username, email, password, is_student, balance)
		VALUES ($1, $2, $3, $4, $5, $6)
		RETURNING id, name, username, email, is_student, balance
	`

	createdUser := domain.User{}
	err = r.dbCon.Get(
		&createdUser,
		query,
		user.Name,
		user.UserName,
		user.Email,
		string(hashedPassword),
		user.IsStudent,
		user.Balance,
	)
	if err != nil {
		return nil, err
	}

	return &createdUser, nil
}

// Find user by username and verify password (login)
func (r *userRepo) Find(userName, password string) (*domain.User, error) {
	user := domain.User{}
	query := `SELECT id, name, username, email, password, is_student, balance FROM users WHERE username=$1`

	err := r.dbCon.Get(&user, query, userName)
	if err != nil {
		return nil, fmt.Errorf("user not found: %w", err)
	}

	// Compare password with hash
	err = bcrypt.CompareHashAndPassword([]byte(user.Password), []byte(password))
	if err != nil {
		return nil, fmt.Errorf("invalid password")
	}

	// Remove password before returning
	user.Password = ""

	return &user, nil
}

func (r *userRepo) DeductBalance(id int64, amount float64) error {
	tx, err := r.dbCon.Beginx()
	if err != nil {
		return err
	}
	defer tx.Rollback()

	var balance float64
	err = tx.Get(&balance, "SELECT balance FROM users WHERE id = $1 FOR UPDATE", id)
	if err != nil {
		return err
	}

	if balance < amount {
		return fmt.Errorf("insufficient balance")
	}

	_, err = tx.Exec("UPDATE users SET balance = balance - $1 WHERE id = $2", amount, id)
	if err != nil {
		return err
	}

	return tx.Commit()
}
