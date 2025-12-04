package cmd

import (
	"context"
	"fmt"
	"swift_transit/bus"
	"swift_transit/config"
	"swift_transit/infra/db"
	"swift_transit/infra/payment"
	"swift_transit/infra/rabbitmq"
	redisConf "swift_transit/infra/redis"
	"swift_transit/location"
	"swift_transit/repo"
	"swift_transit/rest"
	busHandler "swift_transit/rest/handlers/bus"
	routeHandler "swift_transit/rest/handlers/route"
	ticketHandler "swift_transit/rest/handlers/ticket"
	userHandler "swift_transit/rest/handlers/user"
	"swift_transit/rest/middlewares"
	"swift_transit/route"
	"swift_transit/ticket"
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
	// err = redisCon.Set(ctx, "name", "zahid", 0).Err()
	// if err != nil {
	// 	fmt.Println(err.Error())
	// 	panic(err)
	// }
	// val, err := redisCon.Get(ctx, "name").Result()
	// if err != nil {
	// 	fmt.Println(err.Error())
	// 	panic(err)
	// }
	// fmt.Println(val)
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

	ticketSvc := ticket.NewService(ticketRepo, userRepo, redisCon, sslCommerz, rabbitMQ, ctx)

	// Start Ticket Worker
	ticketWorker := ticket.NewTicketWorker(ticketSvc, rabbitMQ)
	go ticketWorker.Start()

	// WebSocket Hub
	hub := location.NewHub()
	go hub.Run()

	userHandler := userHandler.NewHandler(usrSvc, middlewareHandler, mngr, utilHandler, redisCon, ctx, hub)
	routeHandler := routeHandler.NewHandler(routeSvc, middlewareHandler, mngr, utilHandler)
	busHandler := busHandler.NewHandler(busSvc, middlewareHandler, mngr, utilHandler, hub)
	ticketHandler := ticketHandler.NewHandler(ticketSvc, middlewareHandler, mngr, utilHandler)
	handler := rest.NewHandler(cnf, middlewareHandler, userHandler, routeHandler, busHandler, ticketHandler)
	handler.Serve()
}
