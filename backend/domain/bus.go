package domain

type Bus struct {
	Id                int64       `json:"id" db:"id"`
	Name              string      `json:"name" db:"name"`
	LineStringGeoJSON *LineString `json:"linestring_geojson" db:"linestring_geojson"` // Not stored directly, used for geom insertion
	Fare              float64     `json:"fare" db:"fare"`
	Stops             []Stop      `json:"stops"`
}

type BusCredential struct {
	Id                 int64  `json:"id" db:"id"`
	RegistrationNumber string `json:"registration_number" db:"registration_number"`
	Password           string `json:"password" db:"password"`
	RouteId            int64  `json:"route_id" db:"route_id"`
}
