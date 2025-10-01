import requests
import json

# First, submit a sell order
sell_order_data = {
    "user_id": "user2",
    "pair": "BTC/USDT",
    "side": "Sell",
    "order_type": "Limit",
    "price": 50000,
    "amount": 100
}

print("Submitting sell order...")
try:
    response = requests.post(
        "http://localhost:8085/api/orders",
        json=sell_order_data,
        headers={"Content-Type": "application/json"}
    )
    
    if response.status_code == 200:
        print("Sell order submitted successfully!")
        response_data = response.json()
        print(f"Order ID: {response_data.get('order_id')}")
    else:
        print(f"Error submitting sell order: {response.status_code}")
        print(response.text)
        
except Exception as e:
    print(f"Error: {e}")

# Now submit a buy order at the same price to match
buy_order_data = {
    "user_id": "user1",
    "pair": "BTC/USDT",
    "side": "Buy",
    "order_type": "Limit",
    "price": 50000,
    "amount": 100
}

print("\nSubmitting buy order...")
try:
    response = requests.post(
        "http://localhost:8085/api/orders",
        json=buy_order_data,
        headers={"Content-Type": "application/json"}
    )
    
    if response.status_code == 200:
        print("Buy order submitted successfully!")
        response_data = response.json()
        print(f"Order ID: {response_data.get('order_id')}")
    else:
        print(f"Error submitting buy order: {response.status_code}")
        print(response.text)
        
except Exception as e:
    print(f"Error: {e}")

# Trigger order matching
print("\nTriggering order matching...")
try:
    match_response = requests.post(
        "http://localhost:8085/api/match",
        headers={"Content-Type": "application/json"}
    )
    
    if match_response.status_code == 200:
        print("Order matching triggered successfully!")
        match_data = match_response.json()
        trades = match_data.get('trades', [])
        print(f"Number of trades executed: {len(trades)}")
        for trade in trades:
            print(f"Trade ID: {trade.get('id')}")
            print(f"Price: {trade.get('price')}")
            print(f"Quantity: {trade.get('quantity')}")
            print(f"Buyer: {trade.get('buyer_id')}")
            print(f"Seller: {trade.get('seller_id')}")
    else:
        print(f"Error triggering match: {match_response.status_code}")
        print(match_response.text)
        
except Exception as e:
    print(f"Error: {e}")

# Check the final order book
print("\nChecking final order book...")
try:
    book_response = requests.get(
        "http://localhost:8085/api/orderbook/BTC%2FUSDT"
    )
    
    if book_response.status_code == 200:
        print("Order book retrieved successfully!")
        book_data = book_response.json()
        print(f"Pair: {book_data.get('pair')}")
        print(f"Bids: {book_data.get('bids')}")
        print(f"Asks: {book_data.get('asks')}")
    else:
        print(f"Error retrieving order book: {book_response.status_code}")
        print(book_response.text)
        
except Exception as e:
    print(f"Error: {e}")