package db

import (
	"fmt"
	"swift_transit/config"

	"github.com/jmoiron/sqlx"
	_ "github.com/lib/pq"
)

func GetConnectionString(dbCnf *config.DbConfig) string {
	conStr := fmt.Sprintf("user=%s password=%s host=%s port=%d dbname=%s",
		dbCnf.User,
		dbCnf.Password,
		dbCnf.Host,
		dbCnf.Port,
		dbCnf.Name)
	if !dbCnf.EnableSSLMode {
		conStr += " sslmode=disable"
	}

	return conStr
}

func NewConnection(dbCnf *config.DbConfig) (*sqlx.DB, error) {
	dbSource := GetConnectionString(dbCnf)
	dbCon, err := sqlx.Connect("postgres", dbSource)
	if err != nil {
		fmt.Println("Can't connect with database")
		return nil, err
	}
	return dbCon, nil
}
