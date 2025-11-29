package middlewares

import (
	"log"
	"net/http"
	"time"
)

func (h *Handler) Logger(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		start := time.Now()

		// Get the User-Agent from the request headers
		userAgent := r.UserAgent()

		// Log the method, URI, remote address, and User-Agent
		log.Printf("%s %s %s %s", r.Method, r.RequestURI, r.RemoteAddr, userAgent)

		// Call the next handler in the chain
		next.ServeHTTP(w, r)

		// Log the time taken to process the request
		log.Printf("Completed in %v", time.Since(start))
	})
}
