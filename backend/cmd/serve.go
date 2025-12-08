package cmd

import (
	"context"
	"fmt"
	"swift_transit/admin"
	"swift_transit/bus"
	"swift_transit/bus_owner"
	"swift_transit/config"
	"swift_transit/infra/db"
	"swift_transit/infra/payment"
	"swift_transit/infra/rabbitmq"
	redisConf "swift_transit/infra/redis"
	"swift_transit/location"
	"swift_transit/repo"
	"swift_transit/rest"
	adminHandler "swift_transit/rest/handlers/admin"
	busHandler "swift_transit/rest/handlers/bus"
	busOwnerHandler "swift_transit/rest/handlers/bus_owner"
	routeHandler "swift_transit/rest/handlers/route"
	ticketHandler "swift_transit/rest/handlers/ticket"
	transactionHandler "swift_transit/rest/handlers/transaction"
	userHandler "swift_transit/rest/handlers/user"
	"swift_transit/rest/middlewares"
	"swift_transit/route"
	"swift_transit/ticket"
	"swift_transit/transaction"
	"swift_transit/user"
	"swift_transit/utils"
)

func Start() {
	ctx := context.Background()
	cnf := config.Load()
	utilHandler := utils.NewHandler(cnf)
	middlewareHandler := middlewares.NewHandler(utilHandler)
	mngr := middlewareHandler.NewManager()
	redisCon, err := redisConf.NewConnection(&cnf.RedisCnf, ctx)
	if err != nil {
		panic(err)
	}
	fmt.Println(redisCon)
	dbCon, err := db.NewConnection(&cnf.Db)
	if err != nil {
		panic(err)
	}
	err = db.MigrateDB(dbCon, "./migrations")
	if err != nil {
		panic(err)
	}

	//repos
	userRepo := repo.NewUserRepo(dbCon, utilHandler)
	routeRepo := repo.NewRouteRepo(dbCon, utilHandler)
	busRepo := repo.NewBusRepo(dbCon, utilHandler)
	ticketRepo := repo.NewTicketRepo(dbCon, utilHandler)

	//domains
	usrSvc := user.NewService(userRepo)
	routeSvc := route.NewService(routeRepo)
	busSvc := bus.NewService(busRepo, ticketRepo)
	sslCommerz := payment.NewSSLCommerz(cnf.SSLCommerz)

	// RabbitMQ
	rabbitMQ, err := rabbitmq.NewConnection(cnf.RabbitMQ.URL)
	if err != nil {
		panic(err)
	}
	defer rabbitMQ.Close()

	// Transaction
	transactionRepo := repo.NewTransactionRepo(dbCon, utilHandler)
	transactionSvc := transaction.NewService(transactionRepo, userRepo, sslCommerz, redisCon, cnf.PublicBaseURL)
	transHandler := transactionHandler.NewHandler(transactionSvc, middlewareHandler, mngr, utilHandler)

	ticketSvc := ticket.NewService(ticketRepo, userRepo, transactionRepo, redisCon, sslCommerz, rabbitMQ, ctx, cnf.PublicBaseURL)

	// Start Ticket Worker
	// Start Ticket Worker
	ticketWorker := ticket.NewTicketWorker(ticketSvc, rabbitMQ)
	go ticketWorker.Start()

	// Start Ticket Check Worker
	ticketCheckWorker := ticket.NewTicketCheckWorker(ticketSvc, ticketRepo, rabbitMQ)
	go ticketCheckWorker.Start()

	// WebSocket Hub
	hub := location.NewHub()
	go hub.Run()

	userHdlr := userHandler.NewHandler(usrSvc, middlewareHandler, mngr, utilHandler, redisCon, ctx, hub)
	routeHdlr := routeHandler.NewHandler(routeSvc, middlewareHandler, mngr, utilHandler)
	busHdlr := busHandler.NewHandler(busSvc, ticketSvc, middlewareHandler, mngr, utilHandler, hub)
	ticketHdlr := ticketHandler.NewHandler(ticketSvc, middlewareHandler, mngr, utilHandler, cnf.PublicBaseURL)

	busOwnerRepo := repo.NewBusOwnerRepo(dbCon.DB, utilHandler)
	busOwnerSvc := bus_owner.NewService(busOwnerRepo, busRepo, ticketRepo, routeRepo, utilHandler)
	busOwnerHdlr := busOwnerHandler.NewHandler(busOwnerSvc, middlewareHandler, mngr, utilHandler)

	adminRepo := repo.NewAdminRepo(dbCon.DB)
	adminSvc := admin.NewService(adminRepo, utilHandler)
	adminHdlr := adminHandler.NewHandler(adminSvc, utilHandler, middlewareHandler, mngr)

	handler := rest.NewHandler(cnf, middlewareHandler, userHdlr, routeHdlr, busHdlr, ticketHdlr, transHandler, busOwnerHdlr, adminHdlr)
	handler.Serve()
}
