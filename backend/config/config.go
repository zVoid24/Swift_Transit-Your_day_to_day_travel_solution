package config

import (
	"fmt"
	"os"
	"strconv"

	"github.com/joho/godotenv"
)

type DbConfig struct {
	Host          string
	User          string
	Port          int
	Name          string
	Password      string
	EnableSSLMode bool
}

type RedisConfig struct {
	Address  string
	Port     string
	Password string
	DB       int
}

type SSLCommerzConfig struct {
	StoreID   string
	StorePass string
	IsSandbox bool
}

type RabbitMQConfig struct {
	URL string
}

type Config struct {
	Version     string
	HttpPort    string
	ServiceName string
	Secret      string
	Db          DbConfig
	RedisCnf    RedisConfig
	SSLCommerz  SSLCommerzConfig
	RabbitMQ    RabbitMQConfig
}

var configurations *Config

func loadConfig() {

	err := godotenv.Overload()
	if err != nil {
		fmt.Println("Failed to load .env file")
		os.Exit(1)
	}

	version := os.Getenv("VERSION")
	httpPort := os.Getenv("HTTP_PORT")
	serviceName := os.Getenv("SERVICE_NAME")
	secret := os.Getenv("SECRET")
	redisAdr := os.Getenv("REDIS_ADDRESS")
	rdsPort := os.Getenv("REDIS_PORT")
	redisPass := os.Getenv("REDIS_PASSWORD")
	redisDb := os.Getenv("REDIS_DB")

	if version == "" || httpPort == "" || serviceName == "" || secret == "" || redisAdr == "" || rdsPort == "" {
		fmt.Println("Missing required app env variables")
		os.Exit(1)
	}

	redisDB, err := strconv.Atoi(redisDb)
	if err != nil {
		fmt.Println("Invalid Redis DB value in .env")
		os.Exit(1)
	}
	redisAddress := redisAdr + ":" + rdsPort

	host := os.Getenv("HOST")
	user := os.Getenv("USER")
	portStr := os.Getenv("PORT")
	dbName := os.Getenv("NAME")
	password := os.Getenv("PASSWORD")
	enableSSLStr := os.Getenv("ENABLE_SSL_MODE")

	if host == "" || user == "" || portStr == "" || dbName == "" || password == "" || enableSSLStr == "" {
		fmt.Println("Missing required DB env variables")
		os.Exit(1)
	}

	port, err := strconv.Atoi(portStr)
	if err != nil {
		fmt.Println("Invalid PORT value in .env")
		os.Exit(1)
	}

	enableSSL, err := strconv.ParseBool(enableSSLStr)
	if err != nil {
		fmt.Println("Invalid ENABLE_SSL_MODE value in .env")
		os.Exit(1)
	}

	configurations = &Config{
		Version:     version,
		HttpPort:    httpPort,
		ServiceName: serviceName,
		Secret:      secret,
		Db: DbConfig{
			Host:          host,
			User:          user,
			Port:          port,
			Name:          dbName,
			Password:      password,
			EnableSSLMode: enableSSL,
		},
		RedisCnf: RedisConfig{
			Address:  redisAddress,
			Password: redisPass,
			DB:       redisDB,
		},
		SSLCommerz: SSLCommerzConfig{
			StoreID:   os.Getenv("STORE_ID"),
			StorePass: os.Getenv("STORE_PASSWORD"),
			IsSandbox: os.Getenv("IS_SANDBOX") == "true",
		},
		RabbitMQ: RabbitMQConfig{
			URL: os.Getenv("RABBITMQ_URL"),
		},
	}
}

func Load() *Config {
	if configurations == nil {
		loadConfig()
	}
	return configurations
}
