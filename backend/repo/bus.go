package repo

import (
	"swift_transit/bus"
	"swift_transit/domain"
	"swift_transit/utils"

	"github.com/jmoiron/sqlx"
)

type BusRepo interface {
	bus.BusRepo
}

type busRepo struct {
	dbCon       *sqlx.DB
	utilHandler *utils.Handler
}

func NewBusRepo(dbcon *sqlx.DB, utilHandler *utils.Handler) BusRepo {
	return &busRepo{
		dbCon:       dbcon,
		utilHandler: utilHandler,
	}
}

func (r *busRepo) FindBus(start, end string) ([]domain.Bus, error) {
	var buses []domain.Bus
	query := `
		SELECT 
			r.id, 
			r.name, 
			ST_AsGeoJSON(
				ST_LineSubstring(
					r.geom, 
					ST_LineLocatePoint(r.geom, s1.geom), 
					ST_LineLocatePoint(r.geom, s2.geom)
				)
			) as linestring_geojson,
			GREATEST(10, (ST_Length(
				ST_LineSubstring(
					r.geom, 
					ST_LineLocatePoint(r.geom, s1.geom), 
					ST_LineLocatePoint(r.geom, s2.geom)
				)::geography
			) / 1000)*2.5) as fare
		FROM routes r
		JOIN stops s1 ON r.id = s1.route_id
		JOIN stops s2 ON r.id = s2.route_id
		WHERE s1.name = $1 AND s2.name = $2 AND s1.stop_order < s2.stop_order
	`
	err := r.dbCon.Select(&buses, query, start, end)
	if err != nil {
		return nil, err
	}

	for i := range buses {
		// Fetch the two stops
		var stops []domain.Stop
		stopQuery := `
			SELECT id, route_id, stop_order, name, ST_X(geom::geometry) as lon, ST_Y(geom::geometry) as lat 
			FROM stops 
			WHERE route_id = $1 AND (name = $2 OR name = $3)
			ORDER BY stop_order
		`
		err = r.dbCon.Select(&stops, stopQuery, buses[i].Id, start, end)
		if err != nil {
			return nil, err
		}
		buses[i].Stops = stops
	}

	return buses, nil
}

func (r *busRepo) GetBusByRegistrationNumber(regNum string) (*domain.BusCredential, error) {
	var busCred domain.BusCredential
	query := `SELECT * FROM bus_credentials WHERE registration_number = $1`
	err := r.dbCon.Get(&busCred, query, regNum)
	if err != nil {
		return nil, err
	}
	return &busCred, nil
}
