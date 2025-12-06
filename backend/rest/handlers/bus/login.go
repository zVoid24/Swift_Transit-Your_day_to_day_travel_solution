package bus

import (
	"encoding/json"
	"net/http"
)

type LoginRequest struct {
	RegistrationNumber string `json:"registration_number"`
	Password           string `json:"password"`
	Variant            string `json:"variant"`
}

func (h *Handler) Login(w http.ResponseWriter, r *http.Request) {
	var req LoginRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		h.utilHandler.SendError(w, "Invalid request body", http.StatusBadRequest)
		return
	}

	if req.Variant == "" {
		h.utilHandler.SendError(w, "variant is required", http.StatusBadRequest)
		return
	}

	bus, err := h.svc.Login(req.RegistrationNumber, req.Password, req.Variant)
	if err != nil {
		h.utilHandler.SendError(w, "Invalid credentials", http.StatusUnauthorized)
		return
	}

	busData := BusAuthData{
		Id:                 bus.Credential.Id,
		RegistrationNumber: bus.Credential.RegistrationNumber,
		RouteId:            bus.SelectedRouteID,
		Variant:            bus.Variant,
		Variants: []RouteVariant{
			{
				Variant: "up",
				RouteId: bus.Credential.RouteIdUp,
			},
			{
				Variant: "down",
				RouteId: bus.Credential.RouteIdDown,
			},
		},
	}

	token, err := h.utilHandler.CreateJWT(busData)
	if err != nil {
		h.utilHandler.SendError(w, "Failed to generate token", http.StatusInternalServerError)
		return
	}

	resp := AuthResponse{
		Token: token,
		Bus:   busData,
	}

	h.utilHandler.SendData(w, resp, http.StatusOK)
}
