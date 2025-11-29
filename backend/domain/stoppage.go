package domain

type Stop struct {
	Id      int64   `json:"id" db:"id"`
	RouteId int64   `json:"route_id" db:"route_id"`
	Name    string  `json:"name" db:"name"`
	Order   int     `json:"order" db:"stop_order"`
	Lon     float64 `json:"lon" db:"lon"`
	Lat     float64 `json:"lat" db:"lat"`
}
