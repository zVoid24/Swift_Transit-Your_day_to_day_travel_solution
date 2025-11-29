package domain

import (
	"database/sql/driver"
	"encoding/json"
	"errors"
)

type LineString struct {
	Type        string      `json:"type"`
	Coordinates [][]float64 `json:"coordinates"`
}

func (ls *LineString) Scan(value interface{}) error {
	if value == nil {
		return nil
	}
	var data []byte
	switch v := value.(type) {
	case []byte:
		data = v
	case string:
		data = []byte(v)
	default:
		return errors.New("type assertion failed")
	}
	return json.Unmarshal(data, ls)
}

func (ls LineString) Value() (driver.Value, error) {
	b, err := json.Marshal(ls)
	return string(b), err
}

type Route struct {
	Id                int64       `json:"id" db:"id"`
	Name              string      `json:"name" db:"name"`
	LineStringGeoJSON *LineString `json:"linestring_geojson" db:"linestring_geojson"` // Not stored directly, used for geom insertion
	Stops             []Stop      `json:"stops"`
}
