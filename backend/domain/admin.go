package domain

import "time"

type Admin struct {
	Id        int64     `json:"id"`
	Username  string    `json:"username"`
	Password  string    `json:"-"` // Never send password in JSON
	CreatedAt time.Time `json:"created_at"`
}
