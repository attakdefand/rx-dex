# Test script to submit an order to the matching engine
Write-Host "Submitting test order to matching engine..." -ForegroundColor Green

# Define the order data with proper enum values (lowercase)
$body = @{
    user_id = "user1"
    pair = "BTC/USDT"
    side = "buy"
    order_type = "limit"
    price = 50000
    amount = 100
} | ConvertTo-Json

Write-Host "Order data: $body" -ForegroundColor Yellow

try {
    # Submit the order
    $response = Invoke-RestMethod -Uri "http://localhost:8085/api/orders" -Method POST -Body $body -ContentType "application/json"
    Write-Host "Order submitted successfully!" -ForegroundColor Green
    Write-Host "Response: $($response | ConvertTo-Json)" -ForegroundColor Cyan
} catch {
    Write-Host "Error submitting order: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Status Code: $($_.Exception.Response.StatusCode.value__)" -ForegroundColor Red
    Write-Host "Status Description: $($_.Exception.Response.StatusDescription)" -ForegroundColor Red
    
    # Try to read the response content
    try {
        $responseStream = $_.Exception.Response.GetResponseStream()
        $reader = New-Object System.IO.StreamReader($responseStream)
        $responseBody = $reader.ReadToEnd()
        Write-Host "Response Body: $responseBody" -ForegroundColor Red
    } catch {
        Write-Host "Could not read response body: $($_.Exception.Message)" -ForegroundColor Red
    }
}