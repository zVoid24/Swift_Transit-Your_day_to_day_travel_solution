package domain

// model or entity
type User struct {
	Id        int64   `json:"id" db:"id"`
	Name      string  `json:"name" db:"name"`
	UserName  string  `json:"username" db:"username"`
	Email     string  `json:"email" db:"email"`
	Password  string  `json:"password" db:"password"`
	IsStudent bool    `json:"is_student" db:"is_student"`
	Balance   float32 `json:"balance" db:"balance"`
}
