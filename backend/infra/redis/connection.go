package redis

import (
	"context"
	"fmt"
	"swift_transit/config"

	"github.com/go-redis/redis/v8"
)

func NewConnection(redisCnf *config.RedisConfig, ctx context.Context) (*redis.Client, error) {
	client := redis.NewClient(&redis.Options{
		Addr:     redisCnf.Address,
		Password: redisCnf.Password,
		DB:       redisCnf.DB,
	})

	ping, err := client.Ping(ctx).Result()
	if err != nil {
		fmt.Println(err.Error())
		return nil, err
	}
	fmt.Println(ping)
	return client, nil

}
