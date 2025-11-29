package utils

import "swift_transit/config"

type Handler struct {
	cnf *config.Config
}

func NewHandler(cnf *config.Config) *Handler {
	return &Handler{
		cnf: cnf,
	}
}
