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

type ValidationResponse struct {
	Status          string `json:"status"`
	TranDate        string `json:"tran_date"`
	TranID          string `json:"tran_id"`
	ValID           string `json:"val_id"`
	Amount          string `json:"amount"`
	StoreAmount     string `json:"store_amount"`
	Currency        string `json:"currency"`
	BankTranID      string `json:"bank_tran_id"`
	CardType        string `json:"card_type"`
	CardNo          string `json:"card_no"`
	CardIssuer      string `json:"card_issuer"`
	CardBrand       string `json:"card_brand"`
	CardIssuerCountry string `json:"card_issuer_country"`
	CardIssuerCountryCode string `json:"card_issuer_country_code"`
	CurrencyType    string `json:"currency_type"`
	CurrencyAmount  string `json:"currency_amount"`
	CurrencyRate    string `json:"currency_rate"`
	BaseFair        string `json:"base_fair"`
	ValueA          string `json:"value_a"`
	ValueB          string `json:"value_b"`
	ValueC          string `json:"value_c"`
	ValueD          string `json:"value_d"`
	RiskTitle       string `json:"risk_title"`
	RiskLevel       string `json:"risk_level"`
	APIConnect      string `json:"APIConnect"`
	ValidatedOn     string `json:"validated_on"`
	GwVersion       string `json:"gw_version"`
}

func (s *SSLCommerz) ValidateTransaction(valID string) (*ValidationResponse, error) {
	apiUrl := "https://sandbox.sslcommerz.com/validator/api/validationserverAPI.php"
	if !s.Config.IsSandbox {
		apiUrl = "https://securepay.sslcommerz.com/validator/api/validationserverAPI.php"
	}

	u, err := url.Parse(apiUrl)
	if err != nil {
		return nil, err
	}

	q := u.Query()
	q.Set("val_id", valID)
	q.Set("store_id", s.Config.StoreID)
	q.Set("store_passwd", s.Config.StorePass)
	q.Set("format", "json")
	u.RawQuery = q.Encode()

	resp, err := http.Get(u.String())
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()

	var result ValidationResponse
	if err := json.NewDecoder(resp.Body).Decode(&result); err != nil {
		return nil, err
	}

	return &result, nil
}
