use axum::{routing::post, Json, Router};
use dex_messaging::events::TradeEvent;
use serde::{Deserialize, Serialize};
use std::net::SocketAddr;
use tokio::net::TcpListener;

#[derive(Serialize, Deserialize)]
struct MatchOrderRequest {
    order_id: String,
}

#[derive(Serialize)]
struct MatchOrderResponse {
    trades: Vec<Trade>,
}

#[derive(Serialize, Deserialize, Clone)]
struct Trade {
    id: String,
    pair: String,
    price: String,
    amount: String,
    maker_order_id: String,
    taker_order_id: String,
}

async fn match_order(Json(request): Json<MatchOrderRequest>) -> Json<MatchOrderResponse> {
    // Clone the order_id at the beginning to avoid move issues
    let order_id = request.order_id.clone();
    
    // In a real implementation, this would:
    // 1. Fetch the order from database or message queue
    // 2. Match against the order book
    // 3. Generate trades
    // 4. Update order book
    // 5. Publish TradeEvents
    
    println!("Matching order: {}", order_id);
    
    // Simulate matching logic
    let trades = vec![Trade {
        id: uuid::Uuid::new_v4().to_string(),
        pair: "BTC/USDT".to_string(),
        price: "50000.00".to_string(),
        amount: "0.1".to_string(),
        maker_order_id: "maker-123".to_string(),
        taker_order_id: order_id.clone(),
    }];
    
    // Publish trade events
    for trade in &trades {
        let event = TradeEvent {
            trade_id: trade.id.clone(),
            order_id: order_id.clone(),
            maker_order_id: trade.maker_order_id.clone(),
            taker_order_id: trade.taker_order_id.clone(),
            pair: trade.pair.clone(),
            price: trade.price.clone(),
            amount: trade.amount.clone(),
            timestamp: chrono::Utc::now().to_rfc3339(),
        };
        
        println!("Publishing trade event: {:?}", event);
    }
    
    Json(MatchOrderResponse { trades })
}

#[tokio::main]
async fn main() {
    let app = Router::new().route("/api/match", post(match_order));

    let addr: SocketAddr = "0.0.0.0:8085".parse().unwrap();
    let listener = TcpListener::bind(addr).await.unwrap();
    println!("matching-engine listening on http://{}", addr);
    axum::serve(listener, app).await.unwrap();
}