package domain

type BusOwnerAnalytics struct {
	TotalRevenue float64         `json:"total_revenue"`
	TotalTickets int             `json:"total_tickets"`
	Today        PeriodAnalytics `json:"today"`
	Weekly       PeriodAnalytics `json:"weekly"`
	Monthly      PeriodAnalytics `json:"monthly"`
}

type PeriodAnalytics struct {
	Revenue float64 `json:"revenue"`
	Tickets int     `json:"tickets"`
}

type BusAnalytics struct {
	RegistrationNumber string  `json:"registration_number"`
	Tickets            int     `json:"tickets"`
	Revenue            float64 `json:"revenue"`
}
