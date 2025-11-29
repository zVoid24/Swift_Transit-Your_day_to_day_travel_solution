package payment

import (
	"encoding/json"
	"fmt"
	"net/http"
	"net/url"
	"swift_transit/config"
)

type SSLCommerz struct {
	Config config.SSLCommerzConfig
}

func NewSSLCommerz(cnf config.SSLCommerzConfig) *SSLCommerz {
	return &SSLCommerz{
		Config: cnf,
	}
}

type InitResponse struct {
	Status  string `json:"status"`
	Failed  string `json:"failedreason"`
	Gateway string `json:"GatewayPageURL"`
}

func (s *SSLCommerz) InitPayment(amount float64, tranID, successUrl, failUrl, cancelUrl string) (string, error) {
	data := url.Values{}
	data.Set("store_id", s.Config.StoreID)
	data.Set("store_passwd", s.Config.StorePass)
	data.Set("total_amount", fmt.Sprintf("%.2f", amount))
	data.Set("currency", "BDT")
	data.Set("tran_id", tranID)
	data.Set("success_url", successUrl)
	data.Set("fail_url", failUrl)
	data.Set("cancel_url", cancelUrl)
	data.Set("emi_option", "0")
	data.Set("cus_name", "Customer")
	data.Set("cus_email", "customer@example.com")
	data.Set("cus_add1", "Dhaka")
	data.Set("cus_city", "Dhaka")
	data.Set("cus_country", "Bangladesh")
	data.Set("cus_phone", "01700000000")
	data.Set("shipping_method", "NO")
	data.Set("product_name", "Bus Ticket")
	data.Set("product_category", "Ticket")
	data.Set("product_profile", "general")

	apiUrl := "https://sandbox.sslcommerz.com/gwprocess/v4/api.php"
	if !s.Config.IsSandbox {
		apiUrl = "https://securepay.sslcommerz.com/gwprocess/v4/api.php"
	}

	resp, err := http.PostForm(apiUrl, data)
	if err != nil {
		return "", err
	}
	defer resp.Body.Close()

	var result InitResponse
	if err := json.NewDecoder(resp.Body).Decode(&result); err != nil {
		return "", err
	}

	if result.Status == "FAILED" {
		return "", fmt.Errorf("payment init failed: %s", result.Failed)
	}

	return result.Gateway, nil
}
