package ticket

import (
	"log"
	"net/http"
	"strconv"
)

func (h *Handler) PaymentIPN(w http.ResponseWriter, r *http.Request) {
	// Parse form data
	if err := r.ParseForm(); err != nil {
		log.Printf("Failed to parse IPN form data: %v", err)
		w.WriteHeader(http.StatusBadRequest)
		return
	}

	// Extract parameters
	tranID := r.FormValue("tran_id")
	valID := r.FormValue("val_id")
	amountStr := r.FormValue("amount")
	status := r.FormValue("status")
	riskLevel := r.FormValue("risk_level")

	log.Printf("Received IPN: tran_id=%s, val_id=%s, status=%s, amount=%s", tranID, valID, status, amountStr)

	// Check status
	if status != "VALID" && status != "VALIDATED" {
		log.Printf("IPN status not valid: %s", status)
		// We still return 200 to acknowledge receipt, but we don't process it as success
		w.WriteHeader(http.StatusOK)
		return
	}

	// Check risk level (1 = High Risk)
	if riskLevel == "1" {
		log.Printf("IPN risk level high: %s", riskLevel)
		// Hold transaction, maybe notify admin
		w.WriteHeader(http.StatusOK)
		return
	}

	amount, err := strconv.ParseFloat(amountStr, 64)
	if err != nil {
		log.Printf("Invalid amount in IPN: %v", err)
		w.WriteHeader(http.StatusBadRequest)
		return
	}

	// Validate with SSLCommerz Validation API
	valid, err := h.svc.ValidatePayment(valID, tranID, amount)
	if err != nil {
		log.Printf("Payment validation failed: %v", err)
		// If validation fails, it might be a temporary issue or fraud.
		// We log it.
		w.WriteHeader(http.StatusOK) // Acknowledge receipt
		return
	}

	if valid {
		log.Printf("Payment validated successfully for tran_id: %s", tranID)
	} else {
		log.Printf("Payment validation returned false for tran_id: %s", tranID)
	}

	w.WriteHeader(http.StatusOK)
}
