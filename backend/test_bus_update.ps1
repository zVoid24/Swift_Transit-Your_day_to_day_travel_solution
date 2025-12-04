$url = "http://localhost:8080/bus/location"
$body = @{
    bus_id = 101
    route_id = 1
    latitude = 23.8103
    longitude = 90.4125
    speed = 45.5
} | ConvertTo-Json

try {
    $response = Invoke-RestMethod -Uri $url -Method Post -Body $body -ContentType "application/json"
    Write-Host "Response: $response"
} catch {
    Write-Host "Error: $_"
}
