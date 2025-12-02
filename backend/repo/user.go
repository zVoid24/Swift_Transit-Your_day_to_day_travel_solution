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
		Mobile:    dataMap["mobile"].(string),
		NID:       dataMap["nid"].(string),
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
		INSERT INTO users (name, mobile, nid, email, password, is_student, balance)
		VALUES ($1, $2, $3, $4, $5, $6, $7)
		RETURNING id, name, mobile, nid, email, is_student, balance
	`

	createdUser := domain.User{}
	err = r.dbCon.Get(
		&createdUser,
		query,
		user.Name,
		user.Mobile,
		user.NID,
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

// Find user by mobile and verify password (login)
func (r *userRepo) Find(mobile, password string) (*domain.User, error) {
	user := domain.User{}
	query := `SELECT id, name, mobile, nid, email, password, is_student, balance FROM users WHERE mobile=$1`

	err := r.dbCon.Get(&user, query, mobile)
	if err != nil {
		return nil, fmt.Errorf("user not found: %w", err)
	}
	fmt.Printf("Login attempt for mobile %s. Found user with email: %s\n", mobile, user.Email)

	// Compare password with hash
	err = bcrypt.CompareHashAndPassword([]byte(user.Password), []byte(password))
	if err != nil {
		fmt.Printf("Login failed for mobile %s: %v. Stored hash len: %d\n", mobile, err, len(user.Password))
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

func (r *userRepo) UpdatePassword(email, newPassword string) error {
	hashedPassword, err := bcrypt.GenerateFromPassword([]byte(newPassword), bcrypt.DefaultCost)
	if err != nil {
		return err
	}
	fmt.Printf("Updating password for %s. Hash length: %d\n", email, len(hashedPassword))

	query := `UPDATE users SET password = $1 WHERE email = $2`
	res, err := r.dbCon.Exec(query, string(hashedPassword), email)
	if err != nil {
		return err
	}

	rows, err := res.RowsAffected()
	if err != nil {
		return err
	}
	if rows == 0 {
		return fmt.Errorf("no user found with email %s", email)
	}
	return nil
}

func (r *userRepo) FindByEmail(email string) (*domain.User, error) {
	user := domain.User{}
	query := `SELECT id, name, mobile, nid, email, password, is_student, balance FROM users WHERE email=$1`

	err := r.dbCon.Get(&user, query, email)
	if err != nil {
		return nil, fmt.Errorf("user not found: %w", err)
	}
	return &user, nil
}
