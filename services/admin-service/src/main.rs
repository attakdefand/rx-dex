use axum::{
    routing::{get, post},
    Json, Router,
};
use serde::{Deserialize, Serialize};
use std::net::SocketAddr;
use tokio::net::TcpListener;

#[derive(Serialize, Deserialize, Clone)]
struct AdminStats {
    total_users: u32,
    total_orders: u32,
    total_trades: u32,
    system_status: String,
}

#[derive(Serialize, Deserialize, Clone)]
struct User {
    id: String,
    email: String,
    created_at: String,
    status: String,
}

#[derive(Serialize, Deserialize)]
struct AdminLoginRequest {
    username: String,
    password: String,
}

#[derive(Serialize)]
struct AdminLoginResponse {
    token: String,
    success: bool,
}

async fn get_stats() -> Json<AdminStats> {
    Json(AdminStats {
        total_users: 12450,
        total_orders: 87650,
        total_trades: 43210,
        system_status: "Operational".to_string(),
    })
}

async fn get_users() -> Json<Vec<User>> {
    Json(vec![
        User {
            id: "user-001".to_string(),
            email: "user1@example.com".to_string(),
            created_at: "2023-01-15".to_string(),
            status: "Active".to_string(),
        },
        User {
            id: "user-002".to_string(),
            email: "user2@example.com".to_string(),
            created_at: "2023-02-20".to_string(),
            status: "Active".to_string(),
        },
    ])
}

async fn admin_login(Json(request): Json<AdminLoginRequest>) -> Json<AdminLoginResponse> {
    // In a real implementation, this would validate credentials
    // and return a proper JWT token
    if request.username == "admin" && request.password == "admin123" {
        Json(AdminLoginResponse {
            token: "admin-token-12345".to_string(),
            success: true,
        })
    } else {
        Json(AdminLoginResponse {
            token: "".to_string(),
            success: false,
        })
    }
}

#[tokio::main]
async fn main() {
    let app = Router::new()
        .route("/api/admin/stats", get(get_stats))
        .route("/api/admin/users", get(get_users))
        .route("/api/admin/login", post(admin_login));

    let addr: SocketAddr = "0.0.0.0:8088".parse().unwrap();
    let listener = TcpListener::bind(addr).await.unwrap();
    println!("admin-service listening on http://{}", addr);
    axum::serve(listener, app).await.unwrap();
}