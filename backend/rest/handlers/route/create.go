package route

import (
	"encoding/json"
	"fmt"
	"math"
	"net/http"
	"swift_transit/domain"
)

type Property struct {
	Name string `json:"Name"`
	Type string `json:"type"`
}

type Geometry struct {
	Type        string      `json:"type"`
	Coordinates interface{} `json:"coordinates"` // Handle both types with an interface{}
}

type Feature struct {
	Type       string   `json:"type"`
	Properties Property `json:"properties"`
	Geom       Geometry `json:"geometry"`
}

type Geojson struct {
	Name     string    `json:"name"`
	Type     string    `json:"type"`
	Features []Feature `json:"features"`
}

// Handle incoming request and unmarshal JSON
func (h *Handler) Create(w http.ResponseWriter, r *http.Request) {

	// Read the body
	// body, err := io.ReadAll(r.Body)
	// if err != nil {
	// 	w.WriteHeader(http.StatusBadRequest)
	// 	json.NewEncoder(w).Encode(map[string]string{
	// 		"Message": "Failed to read body",
	// 	})
	// 	return
	// }

	// Unmarshal the raw JSON body into a Geojson object
	var jsonData Geojson
	if err := json.NewDecoder(r.Body).Decode(&jsonData); err != nil {
		h.utilHandler.SendError(w, "Invalid JSON payload", http.StatusBadRequest)
		return
	}

	// Extract LineString geometry
	var lineStringGeometry Geometry
	for _, feature := range jsonData.Features {
		if feature.Geom.Type == "LineString" {
			lineStringGeometry = feature.Geom
			break
		}
	}

	// Marshal the LineString geometry to store as LineStringGeoJSON
	lineStringGeoJSON, err := json.Marshal(lineStringGeometry)
	// fmt.Println(lineStringGeometry)
	if err != nil {
		h.utilHandler.SendError(w, "Failed to marshal LineString GeoJSON", http.StatusInternalServerError)
		return
	}

	// Extract Polygons
	stopPolygons := make(map[string]Geometry)
	for _, feature := range jsonData.Features {
		if feature.Geom.Type == "Polygon" && feature.Properties.Type == "stop_area" {
			stopPolygons[feature.Properties.Name] = feature.Geom
		}
	}

	stoppages := []domain.Stop{}
	stopOrder := 1
	for _, feature := range jsonData.Features {
		if feature.Geom.Type == "Point" {
			if coords, ok := feature.Geom.Coordinates.([]interface{}); ok {
				lat := math.Round(coords[1].(float64)*100000) / 100000
				lon := math.Round(coords[0].(float64)*100000) / 100000

				stop := domain.Stop{
					Name:  feature.Properties.Name,
					Order: stopOrder,
					Lon:   lon,
					Lat:   lat,
				}
				stopOrder++

				// Attach polygon if exists
				if poly, exists := stopPolygons[feature.Properties.Name]; exists {
					// Convert Geometry to domain.Polygon
					// Assuming Geometry.Coordinates is compatible with [][][]float64 structure
					// We need to marshal and unmarshal to be safe or type assert carefully
					polyJSON, _ := json.Marshal(poly)
					var domainPoly domain.Polygon
					if err := json.Unmarshal(polyJSON, &domainPoly); err == nil {
						stop.AreaGeom = &domainPoly
					}
				}

				stoppages = append(stoppages, stop)
			}
		}
	}

	var ls domain.LineString
	if err := json.Unmarshal(lineStringGeoJSON, &ls); err != nil {
		h.utilHandler.SendError(w, "Failed to unmarshal LineString", http.StatusInternalServerError)
		return
	}

	route := domain.Route{
		Name:              jsonData.Name,
		LineStringGeoJSON: &ls,
		Stops:             stoppages,
	}

	createdRoute, err := h.svc.Create(route)
	if err != nil {
		h.utilHandler.SendError(w, fmt.Sprintf("Failed to create route: %v", err), http.StatusInternalServerError)
		return
	}

	h.utilHandler.SendData(w, createdRoute, http.StatusOK)
}
