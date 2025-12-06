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

func (h *Handler) GetUserIDFromContext(ctx context.Context) int64 {
	userData := h.GetUserFromContext(ctx)
	if userData == nil {
		return 0
	}

	switch v := userData.(type) {
	case float64:
		return int64(v)
	case int64:
		return v
	case int:
		return int64(v)
	case map[string]interface{}:
		if id, ok := v["id"].(float64); ok {
			return int64(id)
		}
		if id, ok := v["id"].(int64); ok {
			return id
		}
	}
	return 0
}
