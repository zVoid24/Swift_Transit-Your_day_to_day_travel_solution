package location

import (
	"sync"
)

type LocationUpdate struct {
	BusID     int64   `json:"bus_id"`
	RouteID   int64   `json:"route_id"`
	Latitude  float64 `json:"latitude"`
	Longitude float64 `json:"longitude"`
	Speed     float64 `json:"speed"`
}

type Hub struct {
	// Registered clients (users) listening for updates on specific routes
	clients map[*Client]bool

	// Inbound messages from buses
	broadcast chan LocationUpdate

	// Register requests from clients
	register chan *Client

	// Unregister requests from clients
	unregister chan *Client

	// Map routeID to list of clients
	routeClients map[int64]map[*Client]bool

	mu sync.RWMutex
}

func NewHub() *Hub {
	return &Hub{
		broadcast:    make(chan LocationUpdate),
		register:     make(chan *Client),
		unregister:   make(chan *Client),
		clients:      make(map[*Client]bool),
		routeClients: make(map[int64]map[*Client]bool),
	}
}

func (h *Hub) Run() {
	for {
		select {
		case client := <-h.register:
			h.mu.Lock()
			h.clients[client] = true
			if _, ok := h.routeClients[client.routeID]; !ok {
				h.routeClients[client.routeID] = make(map[*Client]bool)
			}
			h.routeClients[client.routeID][client] = true
			h.mu.Unlock()

		case client := <-h.unregister:
			h.mu.Lock()
			if _, ok := h.clients[client]; ok {
				delete(h.clients, client)
				delete(h.routeClients[client.routeID], client)
				close(client.send)
			}
			h.mu.Unlock()

		case update := <-h.broadcast:
			h.mu.RLock()
			clients := h.routeClients[update.RouteID]
			for client := range clients {
				select {
				case client.send <- update:
				default:
					close(client.send)
					delete(h.clients, client)
					delete(h.routeClients[update.RouteID], client)
				}
			}
			h.mu.RUnlock()
		}
	}
}

func (h *Hub) BroadcastLocation(update LocationUpdate) {
	h.broadcast <- update
}
