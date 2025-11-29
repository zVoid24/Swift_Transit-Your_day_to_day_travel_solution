package utils

import (
	"context"
)

type contextKey string

const UserContextKey = contextKey("user")

func (h *Handler) AddToContext(ctx context.Context, userData any) context.Context {
	return context.WithValue(ctx, UserContextKey, userData)
}

func (h *Handler) GetUserFromContext(ctx context.Context) any {
	return ctx.Value(UserContextKey)
}
