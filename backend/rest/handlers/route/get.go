package route

import (
	"encoding/json"
	"net/http"
)

func (h *Handler) SearchRoute(w http.ResponseWriter, r *http.Request) {
	name := r.URL.Query().Get("name")
	if name != "" {
		routes, err := h.svc.SearchByName(name)
		if err != nil {
			h.utilHandler.SendError(w, "failed to search routes", http.StatusInternalServerError)
			return
		}

		h.utilHandler.SendData(w, routes, http.StatusOK)
		return
	}

	start := r.URL.Query().Get("start")
	end := r.URL.Query().Get("end")

	if start == "" || end == "" {
		http.Error(w, "start and end parameters are required", http.StatusBadRequest)
		return
	}

	route, err := h.svc.FindRoute(start, end)
	if err != nil {
		http.Error(w, "route not found", http.StatusNotFound)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(route)
}

func (h *Handler) GetByID(w http.ResponseWriter, r *http.Request) {
	id := h.utilHandler.GetID(r)
	if id == 0 {
		http.Error(w, "invalid id", http.StatusBadRequest)
		return
	}

	route, err := h.svc.FindByID(id)
	if err != nil {
		http.Error(w, "route not found", http.StatusNotFound)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(route)
}
