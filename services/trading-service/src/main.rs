use axum::{
    routing::{get, post},
    Json, Router,
};
use serde::{Deserialize, Serialize};
use std::net::SocketAddr;
use tokio::net::TcpListener;
use uuid::Uuid;

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
struct OrderBook {
    pair: String,
    bids: Vec<OrderBookLevel>,
    asks: Vec<OrderBookLevel>,
}

#[derive(Serialize, Deserialize)]
struct MarketData {
    pairs: Vec<TradePair>,
    order_book: OrderBook,
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

// New data structures for enhanced functionality
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

async fn get_market_overview() -> Json<MarketOverview> {
    // Sample market data
    let pairs = vec![
        TradePair {
            name: "BTC/USDT".to_string(),
            price: "50000.00".to_string(),
            change: "+2.5%".to_string(),
            volume: "1250.50".to_string(),
        },
        TradePair {
            name: "ETH/USDT".to_string(),
            price: "3000.00".to_string(),
            change: "-1.2%".to_string(),
            volume: "5420.30".to_string(),
        },
        TradePair {
            name: "SOL/USDT".to_string(),
            price: "100.00".to_string(),
            change: "+5.3%".to_string(),
            volume: "87500.00".to_string(),
        },
        TradePair {
            name: "ADA/USDT".to_string(),
            price: "0.50".to_string(),
            change: "-0.8%".to_string(),
            volume: "1250000.00".to_string(),
        },
        TradePair {
            name: "DOT/USDT".to_string(),
            price: "7.20".to_string(),
            change: "+3.1%".to_string(),
            volume: "542000.00".to_string(),
        },
    ];

    // Sample recent trades
    let recent_trades = vec![
        RecentTrade {
            id: Uuid::new_v4().to_string(),
            pair: "BTC/USDT".to_string(),
            price: "50000.10".to_string(),
            amount: "0.1".to_string(),
            side: "buy".to_string(),
            timestamp: "2023-01-15T10:30:00Z".to_string(),
        },
        RecentTrade {
            id: Uuid::new_v4().to_string(),
            pair: "ETH/USDT".to_string(),
            price: "2999.50".to_string(),
            amount: "0.5".to_string(),
            side: "sell".to_string(),
            timestamp: "2023-01-15T10:29:45Z".to_string(),
        },
        RecentTrade {
            id: Uuid::new_v4().to_string(),
            pair: "SOL/USDT".to_string(),
            price: "100.20".to_string(),
            amount: "10.0".to_string(),
            side: "buy".to_string(),
            timestamp: "2023-01-15T10:29:30Z".to_string(),
        },
    ];

    Json(MarketOverview { pairs, recent_trades })
}

async fn get_order_book() -> Json<OrderBookResponse> {
    let order_book = OrderBookResponse {
        pair: "BTC/USDT".to_string(),
        bids: vec![
            OrderBookLevel {
                price: "49999.90".to_string(),
                amount: "0.5".to_string(),
                total: "24999.95".to_string(),
            },
            OrderBookLevel {
                price: "49999.50".to_string(),
                amount: "1.2".to_string(),
                total: "59999.40".to_string(),
            },
            OrderBookLevel {
                price: "49999.00".to_string(),
                amount: "0.8".to_string(),
                total: "39999.20".to_string(),
            },
            OrderBookLevel {
                price: "49998.50".to_string(),
                amount: "2.1".to_string(),
                total: "104996.85".to_string(),
            },
            OrderBookLevel {
                price: "49998.00".to_string(),
                amount: "0.3".to_string(),
                total: "14999.40".to_string(),
            },
        ],
        asks: vec![
            OrderBookLevel {
                price: "50000.10".to_string(),
                amount: "0.7".to_string(),
                total: "35000.07".to_string(),
            },
            OrderBookLevel {
                price: "50000.50".to_string(),
                amount: "1.5".to_string(),
                total: "75000.75".to_string(),
            },
            OrderBookLevel {
                price: "50001.00".to_string(),
                amount: "0.9".to_string(),
                total: "45000.90".to_string(),
            },
            OrderBookLevel {
                price: "50001.50".to_string(),
                amount: "1.2".to_string(),
                total: "60001.80".to_string(),
            },
            OrderBookLevel {
                price: "50002.00".to_string(),
                amount: "0.6".to_string(),
                total: "30001.20".to_string(),
            },
        ],
    };

    Json(order_book)
}

async fn place_order(Json(request): Json<PlaceOrderRequest>) -> Json<PlaceOrderResponse> {
    println!(
        "Placing {} order for user {}: {} {} @ {:?}",
        request.order_type, request.user_id, request.side, request.amount, request.price
    );

    // In a real implementation, this would:
    // 1. Validate the order
    // 2. Check user balance
    // 3. Reserve funds
    // 4. Submit to matching engine
    // 5. Return order ID

    let order_id = Uuid::new_v4().to_string();

    Json(PlaceOrderResponse {
        order_id,
        status: "placed".to_string(),
    })
}

async fn cancel_order(Json(request): Json<CancelOrderRequest>) -> Json<CancelOrderResponse> {
    println!("Cancelling order {} for user {}", request.order_id, request.user_id);

    // In a real implementation, this would:
    // 1. Validate the request
    // 2. Check if order exists and belongs to user
    // 3. Cancel the order in the matching engine
    // 4. Release reserved funds

    Json(CancelOrderResponse {
        success: true,
        message: "Order cancelled successfully".to_string(),
    })
}

async fn get_user_orders() -> Json<UserOrdersResponse> {
    // Sample user orders
    let orders = vec![
        UserOrder {
            order_id: "order-123".to_string(),
            pair: "BTC/USDT".to_string(),
            side: "buy".to_string(),
            price: "49999.00".to_string(),
            amount: "0.1".to_string(),
            filled: "0.05".to_string(),
            status: "partially_filled".to_string(),
            created_at: "2023-01-15T10:30:00Z".to_string(),
        },
        UserOrder {
            order_id: "order-456".to_string(),
            pair: "ETH/USDT".to_string(),
            side: "sell".to_string(),
            price: "3000.00".to_string(),
            amount: "0.5".to_string(),
            filled: "0.5".to_string(),
            status: "filled".to_string(),
            created_at: "2023-01-14T15:45:00Z".to_string(),
        },
        UserOrder {
            order_id: "order-789".to_string(),
            pair: "SOL/USDT".to_string(),
            side: "buy".to_string(),
            price: "99.50".to_string(),
            amount: "5.0".to_string(),
            filled: "0.0".to_string(),
            status: "open".to_string(),
            created_at: "2023-01-15T09:15:00Z".to_string(),
        },
    ];

    Json(UserOrdersResponse { orders })
}

#[tokio::main]
async fn main() {
    let app = Router::new()
        .route("/api/market/overview", get(get_market_overview))
        .route("/api/market/orderbook", get(get_order_book))
        .route("/api/orders", post(place_order))
        .route("/api/orders/cancel", post(cancel_order))
        .route("/api/orders/user", get(get_user_orders));

    let addr: SocketAddr = "0.0.0.0:8089".parse().unwrap();
    let listener = TcpListener::bind(addr).await.unwrap();
    println!("trading-service listening on http://{}", addr);
    axum::serve(listener, app).await.unwrap();
}