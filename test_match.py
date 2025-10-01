import requests
import json

# Define the sell order data
sell_order_data = {
    "user_id": "user2",
    "pair": "BTC/USDT",
    "side": "Sell",  # Capitalized
    "order_type": "Limit",  # Capitalized
    "price": 50000,
    "amount": 100
}

# Send the sell order request
try:
    response = requests.post(
        "http://localhost:8085/api/orders",
        json=sell_order_data,
        headers={"Content-Type": "application/json"}
    )
    
    print(f"Status Code: {response.status_code}")
    print(f"Sell Order Response: {response.text}")
    
    if response.status_code == 200:
        print("Sell order submitted successfully!")
        response_data = response.json()
        print(f"Order ID: {response_data.get('order_id')}")
        print(f"Status: {response_data.get('status')}")
    else:
        print(f"Error: {response.status_code}")
        
except requests.exceptions.ConnectionError:
    print("Error: Could not connect to the server. Make sure the matching engine is running.")
except Exception as e:
    print(f"Error: {e}")

# Now trigger order matching
try:
    match_response = requests.post(
        "http://localhost:8085/api/match",
        headers={"Content-Type": "application/json"}
    )
    
    print(f"\nMatch Status Code: {match_response.status_code}")
    print(f"Match Response: {match_response.text}")
    
    if match_response.status_code == 200:
        print("Order matching triggered successfully!")
        match_data = match_response.json()
        trades = match_data.get('trades', [])
        print(f"Number of trades: {len(trades)}")
        for trade in trades:
            print(f"Trade ID: {trade.get('id')}")
            print(f"Price: {trade.get('price')}")
            print(f"Quantity: {trade.get('quantity')}")
    else:
        print(f"Error triggering match: {match_response.status_code}")
        
except requests.exceptions.ConnectionError:
    print("Error: Could not connect to the server. Make sure the matching engine is running.")
except Exception as e:
    print(f"Error: {e}")

# Check the order book
try:
    book_response = requests.get(
        "http://localhost:8085/api/orderbook/BTC%2FUSDT"  # URL encode the slash
    )
    
    print(f"\nOrder Book Status Code: {book_response.status_code}")
    print(f"Order Book Response: {book_response.text}")
    
    if book_response.status_code == 200:
        print("Order book retrieved successfully!")
        book_data = book_response.json()
        print(f"Pair: {book_data.get('pair')}")
        print(f"Bids: {book_data.get('bids')}")
        print(f"Asks: {book_data.get('asks')}")
    else:
        print(f"Error retrieving order book: {book_response.status_code}")
        
except requests.exceptions.ConnectionError:
    print("Error: Could not connect to the server. Make sure the matching engine is running.")
except Exception as e:
    print(f"Error: {e}")