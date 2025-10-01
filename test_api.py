import requests
import json

# Define the order data with proper enum values (capitalized)
order_data = {
    "user_id": "user1",
    "pair": "BTC/USDT",
    "side": "Buy",  # Capitalized
    "order_type": "Limit",  # Capitalized
    "price": 50000,
    "amount": 100
}

# Send the request
try:
    response = requests.post(
        "http://localhost:8085/api/orders",
        json=order_data,
        headers={"Content-Type": "application/json"}
    )
    
    print(f"Status Code: {response.status_code}")
    print(f"Response: {response.text}")
    
    if response.status_code == 200:
        print("Order submitted successfully!")
        response_data = response.json()
        print(f"Order ID: {response_data.get('order_id')}")
        print(f"Status: {response_data.get('status')}")
    else:
        print(f"Error: {response.status_code}")
        
except requests.exceptions.ConnectionError:
    print("Error: Could not connect to the server. Make sure the matching engine is running.")
except Exception as e:
    print(f"Error: {e}")