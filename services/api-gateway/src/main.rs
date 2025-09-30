use axum::{extract::State, response::Html, routing::{get, post}, Json, Router};
use serde::{Deserialize, Serialize};
use std::net::SocketAddr;
use tokio::net::TcpListener;
use tower::limit::ConcurrencyLimitLayer; // ✅ use concurrency limit (Clone-friendly)
use tower_http::{cors::CorsLayer, trace::TraceLayer};

#[derive(Clone)]
struct AppState {
    http: reqwest::Client,
    quoter: String,
    admin_service: String,
    trading_service: String,
}

#[derive(Serialize, Deserialize)]
struct SimpleQuote {
    out: String,
}

#[derive(Serialize, Deserialize)]
struct AdminStats {
    total_users: u32,
    total_orders: u32,
    total_trades: u32,
    system_status: String,
}

#[derive(Serialize, Deserialize)]
struct User {
    id: String,
    email: String,
    created_at: String,
    status: String,
}

// Trading service data structures
#[derive(Serialize, Deserialize, Clone)]
struct TradePair {
    name: String,
    price: String,
    change: String,
    volume: String,
}

#[derive(Serialize, Deserialize)]
struct OrderBookLevel {
    price: String,
    amount: String,
    total: String,
}

#[derive(Serialize, Deserialize)]
struct RecentTrade {
    id: String,
    pair: String,
    price: String,
    amount: String,
    side: String,
    timestamp: String,
}

#[derive(Serialize, Deserialize)]
struct MarketOverview {
    pairs: Vec<TradePair>,
    recent_trades: Vec<RecentTrade>,
}

#[derive(Serialize, Deserialize)]
struct OrderBookResponse {
    pair: String,
    bids: Vec<OrderBookLevel>,
    asks: Vec<OrderBookLevel>,
}

#[derive(Serialize, Deserialize)]
struct PlaceOrderRequest {
    user_id: String,
    pair: String,
    side: String, // buy or sell
    order_type: String, // limit or market
    price: Option<String>, // Required for limit orders
    amount: String,
}

#[derive(Serialize, Deserialize)]
struct PlaceOrderResponse {
    order_id: String,
    status: String,
}

#[derive(Serialize, Deserialize)]
struct CancelOrderRequest {
    order_id: String,
    user_id: String,
}

#[derive(Serialize, Deserialize)]
struct CancelOrderResponse {
    success: bool,
    message: String,
}

#[derive(Serialize, Deserialize)]
struct UserOrder {
    order_id: String,
    pair: String,
    side: String,
    price: String,
    amount: String,
    filled: String,
    status: String,
    created_at: String,
}

#[derive(Serialize, Deserialize)]
struct UserOrdersResponse {
    orders: Vec<UserOrder>,
}

async fn root() -> Html<&'static str> {
    Html("<h1>RX-DEX API</h1>")
}

async fn health() -> &'static str {
    "ok"
}

async fn quote_simple(State(st): State<AppState>) -> Json<SimpleQuote> {
    let url = format!("{}/quote/simple", st.quoter);
    let out = st
        .http
        .get(&url)
        .send()
        .await
        .expect("quoter reachable")
        .json::<SimpleQuote>()
        .await
        .expect("valid json");
    Json(out)
}

async fn admin_stats(State(st): State<AppState>) -> Json<AdminStats> {
    let url = format!("{}/api/admin/stats", st.admin_service);
    let stats = st
        .http
        .get(&url)
        .send()
        .await
        .expect("admin service reachable")
        .json::<AdminStats>()
        .await
        .expect("valid json");
    Json(stats)
}

async fn admin_users(State(st): State<AppState>) -> Json<Vec<User>> {
    let url = format!("{}/api/admin/users", st.admin_service);
    let users = st
        .http
        .get(&url)
        .send()
        .await
        .expect("admin service reachable")
        .json::<Vec<User>>()
        .await
        .expect("valid json");
    Json(users)
}

// Trading service routes
async fn market_overview(State(st): State<AppState>) -> Json<MarketOverview> {
    let url = format!("{}/api/market/overview", st.trading_service);
    let market_data = st
        .http
        .get(&url)
        .send()
        .await
        .expect("trading service reachable")
        .json::<MarketOverview>()
        .await
        .expect("valid json");
    Json(market_data)
}

async fn order_book(State(st): State<AppState>) -> Json<OrderBookResponse> {
    let url = format!("{}/api/market/orderbook", st.trading_service);
    let order_book = st
        .http
        .get(&url)
        .send()
        .await
        .expect("trading service reachable")
        .json::<OrderBookResponse>()
        .await
        .expect("valid json");
    Json(order_book)
}

async fn place_order(State(st): State<AppState>, Json(request): Json<PlaceOrderRequest>) -> Json<PlaceOrderResponse> {
    let url = format!("{}/api/orders", st.trading_service);
    let response = st
        .http
        .post(&url)
        .json(&request)
        .send()
        .await
        .expect("trading service reachable")
        .json::<PlaceOrderResponse>()
        .await
        .expect("valid json");
    Json(response)
}

async fn cancel_order(State(st): State<AppState>, Json(request): Json<CancelOrderRequest>) -> Json<CancelOrderResponse> {
    let url = format!("{}/api/orders/cancel", st.trading_service);
    let response = st
        .http
        .post(&url)
        .json(&request)
        .send()
        .await
        .expect("trading service reachable")
        .json::<CancelOrderResponse>()
        .await
        .expect("valid json");
    Json(response)
}

async fn user_orders(State(st): State<AppState>) -> Json<UserOrdersResponse> {
    let url = format!("{}/api/orders/user", st.trading_service);
    let orders = st
        .http
        .get(&url)
        .send()
        .await
        .expect("trading service reachable")
        .json::<UserOrdersResponse>()
        .await
        .expect("valid json");
    Json(orders)
}

#[tokio::main]
async fn main() {
    let quoter = std::env::var("QUOTER_URL").unwrap_or_else(|_| "http://127.0.0.1:8081".into());
    let admin_service = std::env::var("ADMIN_SERVICE_URL").unwrap_or_else(|_| "http://127.0.0.1:8088".into());
    let trading_service = std::env::var("TRADING_SERVICE_URL").unwrap_or_else(|_| "http://127.0.0.1:8089".into());
    let st = AppState { http: reqwest::Client::new(), quoter, admin_service, trading_service };

    let app = Router::new()
        .route("/", get(root))
        .route("/health", get(health))
        .route("/api/quote/simple", get(quote_simple))
        .route("/api/admin/stats", get(admin_stats))
        .route("/api/admin/users", get(admin_users))
        .route("/api/market/overview", get(market_overview))
        .route("/api/market/orderbook", get(order_book))
        .route("/api/orders", post(place_order))
        .route("/api/orders/cancel", post(cancel_order))
        .route("/api/orders/user", get(user_orders))
        .with_state(st)
        // ✅ These layers are Clone-friendly in this composition:
        .layer(CorsLayer::permissive())
        .layer(TraceLayer::new_for_http())
        .layer(ConcurrencyLimitLayer::new(256)); // allow 256 in-flight reqs

    let addr: SocketAddr = "0.0.0.0:8080".parse().unwrap();
    let listener = TcpListener::bind(addr).await.unwrap();
    println!("api-gateway listening on http://{}", addr);
    axum::serve(listener, app).await.unwrap();
}