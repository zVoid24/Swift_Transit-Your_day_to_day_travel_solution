package repo

import (
	"fmt"
	"swift_transit/domain"
	"swift_transit/route"
	"swift_transit/utils"

	"github.com/jmoiron/sqlx"
	"github.com/lib/pq"
)

type RouteRepo interface {
	route.RouteRepo
	FindRoute(start, end string) (*domain.Route, error)
	SearchByName(query string) ([]domain.Route, error)
	SearchStops(query string) ([]string, error)
}

type routeRepo struct {
	dbCon       *sqlx.DB
	utilHandler *utils.Handler
}

func NewRouteRepo(dbcon *sqlx.DB, utilHandler *utils.Handler) RouteRepo {
	return &routeRepo{
		dbCon:       dbcon,
		utilHandler: utilHandler,
	}
}

func (r *routeRepo) Create(route domain.Route) (*domain.Route, error) {
	tx, err := r.dbCon.Beginx()
	if err != nil {
		return nil, err
	}
	defer tx.Rollback()

	query := `INSERT INTO routes (name, geom) VALUES ($1, ST_Force2D(ST_GeomFromGeoJSON($2))) RETURNING id`
	var routeID int64
	err = tx.QueryRowx(query, route.Name, route.LineStringGeoJSON).Scan(&routeID)
	if err != nil {
		return nil, err
	}
	route.Id = routeID

	if len(route.Stops) > 0 {
		var (
			names  []string
			orders []int
			lons   []float64
			lats   []float64
		)

		for _, stop := range route.Stops {
			names = append(names, stop.Name)
			orders = append(orders, stop.Order)
			lons = append(lons, stop.Lon)
			lats = append(lats, stop.Lat)
		}

		stopQuery := `
			INSERT INTO stops (route_id, name, stop_order, geom)
			SELECT $1, u.name, u.stop_order, ST_SetSRID(ST_MakePoint(u.lon, u.lat), 4326)
			FROM unnest($2::text[], $3::int[], $4::float8[], $5::float8[]) AS u(name, stop_order, lon, lat)
			RETURNING id
		`

		rows, err := tx.Queryx(stopQuery, routeID, pq.Array(names), pq.Array(orders), pq.Array(lons), pq.Array(lats))
		if err != nil {
			return nil, err
		}
		defer rows.Close()

		i := 0
		for rows.Next() {
			var stopID int64
			if err := rows.Scan(&stopID); err != nil {
				return nil, err
			}
			if i < len(route.Stops) {
				route.Stops[i].Id = stopID
				route.Stops[i].RouteId = routeID
				i++
			}
		}
	}

	if err := tx.Commit(); err != nil {
		return nil, err
	}

	return &route, nil
}
func (r *routeRepo) FindAll() ([]domain.Route, error) {
	return nil, nil
}
func (r *routeRepo) FindByID(id int64) (*domain.Route, error) {
	var route domain.Route
	query := `SELECT id, name, ST_AsGeoJSON(geom) as linestring_geojson FROM routes WHERE id = $1`
	err := r.dbCon.Get(&route, query, id)
	if err != nil {
		return nil, err
	}

	var stops []domain.Stop
	stopQuery := `SELECT id, route_id,stop_order,name, ST_X(geom::geometry) as lon, ST_Y(geom::geometry) as lat FROM stops WHERE route_id = $1 ORDER BY stop_order`

	err = r.dbCon.Select(&stops, stopQuery, id)
	fmt.Println(stops)
	if err != nil {
		return nil, err
	}

	route.Stops = stops

	return &route, nil
}

func (r *routeRepo) FindRoute(start, end string) (*domain.Route, error) {
	var route domain.Route
	// Find route that has both stops
	query := `
		SELECT r.id, r.name, ST_AsGeoJSON(r.geom) as linestring_geojson
		FROM routes r
		JOIN stops s1 ON r.id = s1.route_id
		JOIN stops s2 ON r.id = s2.route_id
		WHERE s1.name = $1 AND s2.name = $2
		LIMIT 1
	`
	err := r.dbCon.Get(&route, query, start, end)
	if err != nil {
		return nil, err
	}

	// Fetch stops for this route
	var stops []domain.Stop
	stopQuery := `SELECT id, route_id, stop_order, name, ST_X(geom::geometry) as lon, ST_Y(geom::geometry) as lat FROM stops WHERE route_id = $1 ORDER BY stop_order`
	err = r.dbCon.Select(&stops, stopQuery, route.Id)
	if err != nil {
		return nil, err
	}
	route.Stops = stops

	return &route, nil
}

func (r *routeRepo) SearchByName(query string) ([]domain.Route, error) {
	var routes []domain.Route
	searchQuery := `
SELECT id, name, ST_AsGeoJSON(geom) as linestring_geojson
FROM routes
WHERE name ILIKE $1
ORDER BY name
LIMIT 20
`
	if err := r.dbCon.Select(&routes, searchQuery, "%"+query+"%"); err != nil {
		return nil, err
	}

	if len(routes) == 0 {
		return routes, nil
	}

	var routeIDs []int64
	for _, rt := range routes {
		routeIDs = append(routeIDs, rt.Id)
	}

	stopQuery := `
SELECT id, route_id, stop_order, name, ST_X(geom::geometry) as lon, ST_Y(geom::geometry) as lat
FROM stops
WHERE route_id = ANY($1)
ORDER BY stop_order
`
	var stops []domain.Stop
	if err := r.dbCon.Select(&stops, stopQuery, pq.Array(routeIDs)); err != nil {
		return nil, err
	}

	stopMap := make(map[int64][]domain.Stop)
	for _, stop := range stops {
		stopMap[stop.RouteId] = append(stopMap[stop.RouteId], stop)
	}

	for i := range routes {
		routes[i].Stops = stopMap[routes[i].Id]
	}

	return routes, nil
}

func (r *routeRepo) SearchStops(query string) ([]string, error) {
	var stops []string
	sql := `SELECT DISTINCT name FROM stops WHERE name ILIKE $1 LIMIT 10`
	err := r.dbCon.Select(&stops, sql, "%"+query+"%")
	if err != nil {
		return nil, err
	}
	return stops, nil
}
