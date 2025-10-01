use axum::{routing::{get, post}, Json, Router};
use dex_messaging::events::TradeEvent;
use serde::{Deserialize, Serialize};
use std::{collections::HashMap, net::SocketAddr};
use tokio::net::TcpListener;
use uuid::Uuid;
use dex_data_structures::{OrderBook, Order, OrderSide, OrderType, Trade};

// In-memory order book storage
lazy_static::lazy_static! {
    static ref ORDER_BOOKS: tokio::sync::Mutex<HashMap<String, OrderBook>> = 
        tokio::sync::Mutex::new(HashMap::new());
}

// API Request/Response structures
#[derive(Serialize, Deserialize)]
struct SubmitOrderRequest {
    user_id: String,
    pair: String,
    side: OrderSide,
    order_type: OrderType,
    price: Option<u64>, // Required for limit orders
    amount: u64,
}

#[derive(Serialize)]
struct SubmitOrderResponse {
    order_id: String,
    status: String,
}

#[derive(Serialize)]
struct MatchOrderResponse {
    trades: Vec<Trade>,
}

#[derive(Serialize)]
struct OrderBookResponse {
    pair: String,
    bids: Vec<(u64, u64)>, // (price, total_amount)
    asks: Vec<(u64, u64)>, // (price, total_amount)
}

async fn submit_order(Json(request): Json<SubmitOrderRequest>) -> Json<SubmitOrderResponse> {
    // Validate request
    if request.order_type == OrderType::Limit && request.price.is_none() {
        return Json(SubmitOrderResponse {
            order_id: "".to_string(),
            status: "error: price required for limit orders".to_string(),
        });
    }
    
    // Create order
    let order = Order {
        id: Uuid::new_v4().to_string(),
        user_id: request.user_id,
        side: request.side,
        order_type: request.order_type,
        price: request.price.unwrap_or(0), // 0 for market orders
        quantity: request.amount,
        filled_quantity: 0,
        timestamp: std::time::SystemTime::now()
            .duration_since(std::time::UNIX_EPOCH)
            .unwrap()
            .as_secs(),
    };
    
    let order_id = order.id.clone();
    
    // Get or create order book for this pair
    let mut order_books = ORDER_BOOKS.lock().await;
    let order_book = order_books.entry(request.pair.clone()).or_insert_with(|| {
        OrderBook::new(request.pair.clone())
    });
    
    // Add order to the book
    order_book.add_order(order);
    
    Json(SubmitOrderResponse {
        order_id,
        status: "received".to_string(),
    })
}

async fn match_orders() -> Json<MatchOrderResponse> {
    let mut order_books = ORDER_BOOKS.lock().await;
    let mut all_trades = Vec::new();
    
    // Match orders in all order books
    for order_book in order_books.values_mut() {
        let trades = order_book.match_orders();
        all_trades.extend(trades);
    }
    
    // Publish trade events
    for trade in &all_trades {
        let event = TradeEvent {
            trade_id: trade.id.clone(),
            order_id: trade.buyer_id.clone(), // Simplified
            maker_order_id: trade.seller_id.clone(), // Simplified
            taker_order_id: trade.buyer_id.clone(), // Simplified
            pair: "BTC/USDT".to_string(), // Simplified
            price: trade.price.to_string(),
            amount: trade.quantity.to_string(),
            timestamp: chrono::Utc::now().to_rfc3339(),
        };
        
        println!("Publishing trade event: {:?}", event);
        // In real implementation: dex_messaging::publisher::publish("trades", event).await;
    }
    
    Json(MatchOrderResponse { trades: all_trades })
}

async fn get_order_book(pair: String) -> Json<OrderBookResponse> {
    let order_books = ORDER_BOOKS.lock().await;
    
    let (bids, asks) = if let Some(order_book) = order_books.get(&pair) {
        // Aggregate buy orders by price
        let mut bids = Vec::new();
        for (price, level) in order_book.bids.iter() {
            let total_quantity: u64 = level.quantity;
            if total_quantity > 0 {
                bids.push((*price, total_quantity));
            }
        }
        
        // Aggregate sell orders by price
        let mut asks = Vec::new();
        for (price, level) in order_book.asks.iter() {
            let total_quantity: u64 = level.quantity;
            if total_quantity > 0 {
                asks.push((*price, total_quantity));
            }
        }
        
        (bids, asks)
    } else {
        (Vec::new(), Vec::new())
    };
    
    Json(OrderBookResponse {
        pair,
        bids,
        asks,
    })
}

#[tokio::main]
async fn main() {
    // Initialize lazy static
    lazy_static::initialize(&ORDER_BOOKS);
    
    let app = Router::new()
        .route("/api/orders", post(submit_order))
        .route("/api/match", post(match_orders))
        .route("/api/orderbook/:pair", get(|axum::extract::Path(pair): axum::extract::Path<String>| async move {
            get_order_book(pair).await
        }));

    let addr: SocketAddr = "0.0.0.0:8085".parse().unwrap();
    let listener = TcpListener::bind(addr).await.unwrap();
    println!("matching-engine listening on http://{}", addr);
    axum::serve(listener, app).await.unwrap();
}