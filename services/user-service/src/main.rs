use axum::{
    routing::{get, post},
    Json, Router,
};
use dex_messaging::events::UserBalanceEvent;
use serde::{Deserialize, Serialize};
use std::net::SocketAddr;
use tokio::net::TcpListener;

#[derive(Serialize, Deserialize, Clone)]
struct User {
    id: String,
    email: String,
    created_at: String,
}

#[derive(Serialize, Deserialize)]
struct CreateUserRequest {
    email: String,
}

#[derive(Serialize)]
struct CreateUserResponse {
    user_id: String,
    email: String,
    status: String,
}

#[derive(Serialize)]
struct GetUserResponse {
    user: User,
}

#[derive(Serialize, Deserialize)]
struct UpdateBalanceRequest {
    user_id: String,
    asset: String,
    amount: String,
}

async fn create_user(Json(request): Json<CreateUserRequest>) -> Json<CreateUserResponse> {
    let user_id = uuid::Uuid::new_v4().to_string();
    
    // In a real implementation, this would:
    // 1. Validate the email
    // 2. Store user in database
    // 3. Publish a UserCreatedEvent
    
    println!("Created user: {} with email: {}", user_id, request.email);
    
    Json(CreateUserResponse {
        user_id: user_id.clone(),
        email: request.email,
        status: "active".to_string(),
    })
}

async fn get_user() -> Json<GetUserResponse> {
    // In a real implementation, this would:
    // 1. Get user ID from auth context
    // 2. Fetch user from database
    
    Json(GetUserResponse {
        user: User {
            id: "user-123".to_string(),
            email: "user@example.com".to_string(),
            created_at: chrono::Utc::now().to_rfc3339(),
        },
    })
}

async fn update_balance(Json(request): Json<UpdateBalanceRequest>) -> Json<&'static str> {
    // In a real implementation, this would:
    // 1. Validate the request
    // 2. Update user balance in database
    // 3. Publish a UserBalanceEvent
    
    let event = UserBalanceEvent {
        user_id: request.user_id,
        asset: request.asset,
        balance: request.amount,
        timestamp: chrono::Utc::now().to_rfc3339(),
    };
    
    println!("Updated balance for user: {:?}", event);
    
    Json("Balance updated")
}

#[tokio::main]
async fn main() {
    let app = Router::new()
        .route("/api/users", post(create_user))
        .route("/api/users/me", get(get_user))
        .route("/api/users/balance", post(update_balance));

    let addr: SocketAddr = "0.0.0.0:8084".parse().unwrap();
    let listener = TcpListener::bind(addr).await.unwrap();
    println!("user-service listening on http://{}", addr);
    axum::serve(listener, app).await.unwrap();
}