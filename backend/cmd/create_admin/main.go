package main

import (
	"database/sql"
	"fmt"
	"log"

	"github.com/joho/godotenv"
	_ "github.com/lib/pq"
	"golang.org/x/crypto/bcrypt"
)

func main() {
	// Load environment variables
	if err := godotenv.Load(); err != nil {
		log.Println("No .env file found, using environment variables")
	}

	// Get database connection string
	dbHost := "localhost"
	dbPort := "5432"
	dbUser := "postgres"
	dbPassword := "8135"
	dbName := "swift_transit"

	connStr := fmt.Sprintf("host=%s port=%s user=%s password=%s dbname=%s sslmode=disable",
		dbHost, dbPort, dbUser, dbPassword, dbName)

	// Connect to database
	db, err := sql.Open("postgres", connStr)
	if err != nil {
		log.Fatal("Failed to connect to database:", err)
	}
	defer db.Close()

	// Test connection
	if err := db.Ping(); err != nil {
		log.Fatal("Failed to ping database:", err)
	}

	fmt.Println("Connected to database successfully")

	// Admin credentials
	username := "admin"
	password := "admin123" // Change this to a secure password

	// Hash the password
	hashedPassword, err := bcrypt.GenerateFromPassword([]byte(password), bcrypt.DefaultCost)
	if err != nil {
		log.Fatal("Failed to hash password:", err)
	}

	// Insert admin into database
	query := `INSERT INTO admins (username, password) VALUES ($1, $2) 
	          ON CONFLICT (username) DO UPDATE SET password = EXCLUDED.password`

	_, err = db.Exec(query, username, string(hashedPassword))
	if err != nil {
		log.Fatal("Failed to insert admin:", err)
	}

	fmt.Printf("✓ Admin user created successfully\n")
	fmt.Printf("  Username: %s\n", username)
	fmt.Printf("  Password: %s\n", password)
	fmt.Println("\n⚠️  IMPORTANT: Change the password in production!")
}
