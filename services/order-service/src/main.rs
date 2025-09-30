use axum::{routing::post, Json, Router};
use dex_messaging::events::OrderEvent;
use serde::{Deserialize, Serialize};
use std::net::SocketAddr;
use tokio::net::TcpListener;

#[derive(Serialize, Deserialize)]
struct OrderRequest {
    user_id: String,
    pair: String,
    side: String, // buy or sell
    price: String,
    amount: String,
}

#[derive(Serialize)]
struct OrderResponse {
    order_id: String,
    status: String,
}

async fn submit_order(Json(order): Json<OrderRequest>) -> Json<OrderResponse> {
    // In a real implementation, this would:
    // 1. Validate the order
    // 2. Publish an OrderEvent to the message queue
    // 3. Return order ID immediately
    
    println!("Received order for user: {}", order.user_id);
    
    // Simulate publishing to message queue
    let event = OrderEvent {
        order_id: uuid::Uuid::new_v4().to_string(),
        user_id: order.user_id,
        pair: order.pair,
        side: order.side,
        price: order.price,
        amount: order.amount,
        timestamp: chrono::Utc::now().to_rfc3339(),
    };
    
    // In real implementation: dex_messaging::publisher::publish("orders", event).await;
    
    Json(OrderResponse {
        order_id: event.order_id,
        status: "received".to_string(),
    })
}

#[tokio::main]
async fn main() {
    let app = Router::new()
        .route("/api/orders", post(submit_order));

    let addr: SocketAddr = "0.0.0.0:8083".parse().unwrap();
    let listener = TcpListener::bind(addr).await.unwrap();
    println!("order-service listening on http://{}", addr);
    axum::serve(listener, app).await.unwrap();
}