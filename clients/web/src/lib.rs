use yew::prelude::*;
use yew::platform::spawn_local;
use gloo::net::http::Request;
use serde::{Deserialize, Serialize};
use std::collections::HashMap;
use wasm_bindgen::JsCast;
use web_sys::{window, HtmlInputElement};

// Data structures for API responses
#[derive(Serialize, Deserialize, Debug, Clone)]
struct SimpleQuote {
    out: String,
}

// Trading service data structures
#[derive(Serialize, Deserialize, Debug, Clone, PartialEq)]
struct TradePair {
    name: String,
    price: String,
    change: String,
    volume: String,
}

#[derive(Serialize, Deserialize, Debug, Clone)]
struct OrderBookLevel {
    price: String,
    amount: String,
    total: String,
}

#[derive(Serialize, Deserialize, Debug, Clone)]
struct OrderBookResponse {
    pair: String,
    bids: Vec<OrderBookLevel>,
    asks: Vec<OrderBookLevel>,
}

#[derive(Serialize, Deserialize, Debug, Clone)]
struct RecentTrade {
    id: String,
    pair: String,
    price: String,
    amount: String,
    side: String,
    timestamp: String,
}

#[derive(Serialize, Deserialize, Debug, Clone)]
struct MarketOverview {
    pairs: Vec<TradePair>,
    recent_trades: Vec<RecentTrade>,
}

#[derive(Serialize, Deserialize, Debug, Clone)]
struct PlaceOrderRequest {
    user_id: String,
    pair: String,
    side: String,
    order_type: String,
    price: Option<String>,
    amount: String,
}

#[derive(Serialize, Deserialize, Debug, Clone)]
struct PlaceOrderResponse {
    order_id: String,
    status: String,
}

#[derive(Serialize, Deserialize, Debug, Clone)]
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

#[derive(Serialize, Deserialize, Debug, Clone)]
struct UserOrdersResponse {
    orders: Vec<UserOrder>,
}

#[derive(Serialize, Deserialize, Debug, Clone)]
struct Wallet {
    user_id: String,
    asset: String,
    balance: String,
    reserved: String,
}

// Admin data structures
#[derive(Serialize, Deserialize, Debug, Clone)]
struct AdminStats {
    total_users: u32,
    total_orders: u32,
    total_trades: u32,
    system_status: String,
}

#[derive(Serialize, Deserialize, Debug, Clone)]
struct User {
    id: String,
    email: String,
    created_at: String,
    status: String,
}

// Main application state
#[derive(Debug, Clone)]
enum AppState {
    Loading,
    Ready {
        user_id: String,
        wallet: Wallet,
        market_overview: MarketOverview,
        selected_pair: TradePair,
        order_book: OrderBookResponse,
        quote_result: Option<SimpleQuote>,
        user_orders: Vec<UserOrder>,
        // Admin specific fields
        is_admin: bool,
        admin_stats: Option<AdminStats>,
        users: Vec<User>,
    },
    Error(String),
}

// Main application component
#[function_component(App)]
pub fn app() -> Html {
    let state = use_state(|| AppState::Loading);
    
    // Initialize the app
    {
        let state = state.clone();
        use_effect_with((), move |_| {
            spawn_local(async move {
                // Simulate user login
                let user_id = "user-123".to_string();
                
                // Check if user is admin (in real app, this would come from auth)
                let is_admin = user_id == "admin-123";
                
                // Fetch wallet info
                let wallet = Wallet {
                    user_id: user_id.clone(),
                    asset: "BTC".to_string(),
                    balance: "1.5".to_string(),
                    reserved: "0.2".to_string(),
                };
                
                // Fetch market overview
                let market_overview = MarketOverview {
                    pairs: vec![
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
                    ],
                    recent_trades: vec![
                        RecentTrade {
                            id: "trade-1".to_string(),
                            pair: "BTC/USDT".to_string(),
                            price: "50000.10".to_string(),
                            amount: "0.1".to_string(),
                            side: "buy".to_string(),
                            timestamp: "2023-01-15T10:30:00Z".to_string(),
                        },
                        RecentTrade {
                            id: "trade-2".to_string(),
                            pair: "ETH/USDT".to_string(),
                            price: "2999.50".to_string(),
                            amount: "0.5".to_string(),
                            side: "sell".to_string(),
                            timestamp: "2023-01-15T10:29:45Z".to_string(),
                        },
                        RecentTrade {
                            id: "trade-3".to_string(),
                            pair: "SOL/USDT".to_string(),
                            price: "100.20".to_string(),
                            amount: "10.0".to_string(),
                            side: "buy".to_string(),
                            timestamp: "2023-01-15T10:29:30Z".to_string(),
                        },
                    ],
                };
                
                let selected_pair = market_overview.pairs[0].clone();
                
                // Fetch order book
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
                
                // Sample user orders
                let user_orders = vec![
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
                
                // Admin data (if applicable)
                let mut admin_stats = None;
                let mut users = vec![];
                
                if is_admin {
                    admin_stats = Some(AdminStats {
                        total_users: 12450,
                        total_orders: 87650,
                        total_trades: 43210,
                        system_status: "Operational".to_string(),
                    });
                    
                    users = vec![
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
                    ];
                }
                
                state.set(AppState::Ready {
                    user_id,
                    wallet,
                    market_overview,
                    selected_pair,
                    order_book,
                    quote_result: None,
                    user_orders,
                    is_admin,
                    admin_stats,
                    users,
                });
            });
            || {}
        });
    }
    
    let onclick_quote = {
        let state = state.clone();
        Callback::from(move |_| {
            let state = state.clone();
            spawn_local(async move {
                match Request::get("/api/quote/simple")
                    .send()
                    .await {
                        Ok(resp) => {
                            match resp.json::<SimpleQuote>().await {
                                Ok(quote) => {
                                    if let AppState::Ready { user_id, wallet, market_overview, selected_pair, order_book, user_orders, is_admin, admin_stats, users, .. } = &*state {
                                        state.set(AppState::Ready {
                                            user_id: user_id.clone(),
                                            wallet: wallet.clone(),
                                            market_overview: market_overview.clone(),
                                            selected_pair: selected_pair.clone(),
                                            order_book: order_book.clone(),
                                            quote_result: Some(quote),
                                            user_orders: user_orders.clone(),
                                            is_admin: is_admin.clone(),
                                            admin_stats: admin_stats.clone(),
                                            users: users.clone(),
                                        });
                                    }
                                },
                                Err(_) => state.set(AppState::Error("Failed to parse quote response".to_string())),
                            }
                        },
                        Err(_) => state.set(AppState::Error("Failed to fetch quote".to_string())),
                    }
            });
        })
    };
    
    let on_pair_select = {
        let state = state.clone();
        Callback::from(move |pair: TradePair| {
            if let AppState::Ready { user_id, wallet, market_overview, quote_result, order_book, user_orders, is_admin, admin_stats, users, .. } = &*state {
                state.set(AppState::Ready {
                    user_id: user_id.clone(),
                    wallet: wallet.clone(),
                    market_overview: market_overview.clone(),
                    selected_pair: pair,
                    order_book: order_book.clone(),
                    quote_result: quote_result.clone(),
                    user_orders: user_orders.clone(),
                    is_admin: is_admin.clone(),
                    admin_stats: admin_stats.clone(),
                    users: users.clone(),
                });
            }
        })
    };
    
    let on_submit_order = {
        let state = state.clone();
        Callback::from(move |(side, price, amount): (String, String, String)| {
            let state = state.clone();
            spawn_local(async move {
                if let AppState::Ready { selected_pair, user_id, .. } = &*state {
                    let order_request = PlaceOrderRequest {
                        user_id: user_id.clone(),
                        pair: selected_pair.name.clone(),
                        side,
                        order_type: "limit".to_string(),
                        price: Some(price),
                        amount,
                    };
                    
                    // In a real implementation, this would call the API gateway
                    // For now, we'll just simulate a successful order
                    let order_response = PlaceOrderResponse {
                        order_id: "order-12345".to_string(),
                        status: "submitted".to_string(),
                    };
                    
                    // Update UI to show order confirmation
                    web_sys::console::log_1(&format!("Order submitted: {:?}", order_response).into());
                }
            });
        })
    };
    
    match &*state {
        AppState::Loading => {
            html! {
                <div class="loading">
                    <h1>{ "Loading RX-DEX..." }</h1>
                    <div class="spinner"></div>
                </div>
            }
        },
        AppState::Ready { user_id, wallet, market_overview, selected_pair, order_book, quote_result, user_orders, is_admin, admin_stats, users } => {
            html! {
                <div class="dex-app">
                    <header class="app-header">
                        <div class="header-left">
                            <h1><i class="fas fa-exchange-alt"></i> { " RX-DEX" }</h1>
                        </div>
                        <div class="header-right">
                            if *is_admin {
                                <span class="user-info admin">
                                    <i class="fas fa-crown"></i>
                                    { "Admin" }
                                </span>
                            }
                            <span class="user-info">
                                <i class="fas fa-user"></i>
                                { format!("User: {}", user_id) }
                            </span>
                            <span class="wallet-info">
                                <i class="fas fa-wallet"></i>
                                { format!("{}: {}", wallet.asset, wallet.balance) }
                            </span>
                        </div>
                    </header>
                    
                    <div class="app-content">
                        <div class="sidebar">
                            <div class="market-overview">
                                <h2><i class="fas fa-chart-line"></i> { " Markets" }</h2>
                                <ul class="trade-pairs">
                                    { for market_overview.pairs.iter().map(|pair| {
                                        let onclick = {
                                            let pair = pair.clone();
                                            let on_pair_select = on_pair_select.clone();
                                            Callback::from(move |_| {
                                                on_pair_select.emit(pair.clone());
                                            })
                                        };
                                        let is_selected = pair.name == selected_pair.name;
                                        html! {
                                            <li class={if is_selected { "selected" } else { "" }} onclick={onclick}>
                                                <div class="pair-name">{ &pair.name }</div>
                                                <div class="pair-price">{ &pair.price }</div>
                                                <div class={if pair.change.starts_with('+') { "change positive" } else { "change negative" }}>
                                                    { &pair.change }
                                                </div>
                                            </li>
                                        }
                                    }) }
                                </ul>
                            </div>
                            
                            <div class="wallet-info">
                                <h2><i class="fas fa-wallet"></i> { " Wallet" }</h2>
                                <div class="wallet-assets">
                                    <div class="asset">
                                        <span>{ "BTC" }</span>
                                        <span>{ &wallet.balance }</span>
                                    </div>
                                    <div class="asset">
                                        <span>{ "USDT" }</span>
                                        <span>{ "15000.00" }</span>
                                    </div>
                                    <div class="asset">
                                        <span>{ "ETH" }</span>
                                        <span>{ "10.0" }</span>
                                    </div>
                                    <div class="asset">
                                        <span>{ "SOL" }</span>
                                        <span>{ "50.0" }</span>
                                    </div>
                                </div>
                            </div>
                            
                            <div class="recent-trades">
                                <h2><i class="fas fa-history"></i> { " Recent Orders" }</h2>
                                <div class="orders-list">
                                    { for user_orders.iter().map(|order| {
                                        html! {
                                            <div class="order-item">
                                                <div class="order-header">
                                                    <span class={if order.side == "buy" { "buy" } else { "sell" }}>
                                                        { format!("{} {}", order.side, order.pair) }
                                                    </span>
                                                    <span class="order-status">{ &order.status.replace("_", " ") }</span>
                                                </div>
                                                <div class="order-details">
                                                    <span>{ format!("Price: {}", order.price) }</span>
                                                    <span>{ format!("Amount: {}", order.amount) }</span>
                                                    <span>{ format!("Filled: {}", order.filled) }</span>
                                                </div>
                                            </div>
                                        }
                                    }) }
                                </div>
                            </div>
                            
                            // Admin panel (only visible to admins)
                            if *is_admin {
                                <div class="admin-panel">
                                    <h2><i class="fas fa-shield-alt"></i> { " Admin Panel" }</h2>
                                    if let Some(stats) = admin_stats {
                                        <div class="admin-stats">
                                            <div class="stat-card">
                                                <h3>{ "Users" }</h3>
                                                <p>{ stats.total_users }</p>
                                            </div>
                                            <div class="stat-card">
                                                <h3>{ "Orders" }</h3>
                                                <p>{ stats.total_orders }</p>
                                            </div>
                                            <div class="stat-card">
                                                <h3>{ "Trades" }</h3>
                                                <p>{ stats.total_trades }</p>
                                            </div>
                                            <div class="stat-card">
                                                <h3>{ "Status" }</h3>
                                                <p class="status">{ &stats.system_status }</p>
                                            </div>
                                        </div>
                                    }
                                    
                                    <div class="user-management">
                                        <h3><i class="fas fa-users"></i> { " User Management" }</h3>
                                        <table class="user-table">
                                            <thead>
                                                <tr>
                                                    <th>{ "ID" }</th>
                                                    <th>{ "Email" }</th>
                                                    <th>{ "Created" }</th>
                                                    <th>{ "Status" }</th>
                                                    <th>{ "Actions" }</th>
                                                </tr>
                                            </thead>
                                            <tbody>
                                                { for users.iter().map(|user| {
                                                    html! {
                                                        <tr>
                                                            <td>{ &user.id }</td>
                                                            <td>{ &user.email }</td>
                                                            <td>{ &user.created_at }</td>
                                                            <td>{ &user.status }</td>
                                                            <td>
                                                                <button class="btn-action"><i class="fas fa-edit"></i></button>
                                                                <button class="btn-action"><i class="fas fa-ban"></i></button>
                                                            </td>
                                                        </tr>
                                                    }
                                                }) }
                                            </tbody>
                                        </table>
                                    </div>
                                </div>
                            }
                        </div>
                        
                        <div class="main-content">
                            <div class="trading-panel">
                                <div class="panel-header">
                                    <h2>{ &selected_pair.name }</h2>
                                    <div class="current-price">
                                        { format!("{} {}", selected_pair.price, if selected_pair.change.starts_with('+') { "↑" } else { "↓" }) }
                                        <span class={if selected_pair.change.starts_with('+') { "change positive" } else { "change negative" }}>
                                            { &selected_pair.change }
                                        </span>
                                    </div>
                                </div>
                                
                                <div class="order-form">
                                    <div class="form-tabs">
                                        <button class="tab active">{ "Limit" }</button>
                                        <button class="tab">{ "Market" }</button>
                                    </div>
                                    
                                    <div class="form-content">
                                        <div class="form-group">
                                            <label>{ "Price" }</label>
                                            <input type="text" placeholder="0.00" id="price-input" />
                                        </div>
                                        
                                        <div class="form-group">
                                            <label>{ "Amount" }</label>
                                            <input type="text" placeholder="0.00" id="amount-input" />
                                        </div>
                                        
                                        <div class="form-group">
                                            <label>{ "Total" }</label>
                                            <input type="text" placeholder="0.00" id="total-input" />
                                        </div>
                                        
                                        <div class="order-buttons">
                                            <button class="btn buy" onclick={
                                                let on_submit_order = on_submit_order.clone();
                                                Callback::from(move |_| {
                                                    let document = window().unwrap().document().unwrap();
                                                    let price = document.get_element_by_id("price-input").unwrap()
                                                        .dyn_into::<HtmlInputElement>().unwrap().value();
                                                    let amount = document.get_element_by_id("amount-input").unwrap()
                                                        .dyn_into::<HtmlInputElement>().unwrap().value();
                                                    on_submit_order.emit(("buy".to_string(), price, amount));
                                                })
                                            }>{ "Buy" }</button>
                                            <button class="btn sell" onclick={
                                                let on_submit_order = on_submit_order.clone();
                                                Callback::from(move |_| {
                                                    let document = window().unwrap().document().unwrap();
                                                    let price = document.get_element_by_id("price-input").unwrap()
                                                        .dyn_into::<HtmlInputElement>().unwrap().value();
                                                    let amount = document.get_element_by_id("amount-input").unwrap()
                                                        .dyn_into::<HtmlInputElement>().unwrap().value();
                                                    on_submit_order.emit(("sell".to_string(), price, amount));
                                                })
                                            }>{ "Sell" }</button>
                                        </div>
                                    </div>
                                </div>
                                
                                <div class="quote-section">
                                    <button onclick={onclick_quote} class="btn quote-btn">
                                        { "Get Quote" }
                                    </button>
                                    if let Some(quote) = quote_result {
                                        <div class="quote-result">
                                            <p>{ format!("Quote result: {}", quote.out) }</p>
                                        </div>
                                    }
                                </div>
                            </div>
                            
                            <div class="order-book">
                                <h2><i class="fas fa-book"></i> { " Order Book" }</h2>
                                <div class="order-book-content">
                                    <div class="sell-orders">
                                        { for order_book.asks.iter().map(|level| {
                                            html! {
                                                <div class="order-row">
                                                    <span class="price">{ &level.price }</span>
                                                    <span class="amount">{ &level.amount }</span>
                                                    <span class="total">{ &level.total }</span>
                                                </div>
                                            }
                                        }) }
                                    </div>
                                    
                                    <div class="current-price">
                                        <span>{ &selected_pair.price }</span>
                                    </div>
                                    
                                    <div class="buy-orders">
                                        { for order_book.bids.iter().map(|level| {
                                            html! {
                                                <div class="order-row">
                                                    <span class="price">{ &level.price }</span>
                                                    <span class="amount">{ &level.amount }</span>
                                                    <span class="total">{ &level.total }</span>
                                                </div>
                                            }
                                        }) }
                                    </div>
                                </div>
                            </div>
                        </div>
                        
                        <div class="market-data">
                            <div class="recent-trades-section">
                                <h2><i class="fas fa-exchange-alt"></i> { " Recent Trades" }</h2>
                                <div class="trades-list">
                                    { for market_overview.recent_trades.iter().map(|trade| {
                                        html! {
                                            <div class="trade-item">
                                                <span class={if trade.side == "buy" { "buy" } else { "sell" }}>
                                                    { &trade.price }
                                                </span>
                                                <span>{ &trade.amount }</span>
                                                <span>{ &trade.timestamp }</span>
                                            </div>
                                        }
                                    }) }
                                </div>
                            </div>
                        </div>
                    </div>
                    
                    <footer class="app-footer">
                        <p>{ "RX-DEX - A high-performance decentralized exchange" }</p>
                        <p>{ "© 2025 RX-DEX. All rights reserved." }</p>
                    </footer>
                    
                    <style>
                        {r#"
                        /* DEX Application Styles */
                        
                        /* Global Styles */
                        body {
                          margin: 0;
                          padding: 0;
                          font-family: 'Roboto', sans-serif;
                          background-color: #0f172a;
                          color: #f1f5f9;
                          height: 100vh;
                          overflow: hidden;
                        }
                        
                        #root {
                          height: 100vh;
                        }
                        
                        /* Loading Screen */
                        .loading {
                          display: flex;
                          flex-direction: column;
                          justify-content: center;
                          align-items: center;
                          height: 100vh;
                          background-color: #0f172a;
                        }
                        
                        .spinner {
                          width: 50px;
                          height: 50px;
                          border: 5px solid rgba(255, 255, 255, 0.3);
                          border-radius: 50%;
                          border-top-color: #3b82f6;
                          animation: spin 1s ease-in-out infinite;
                          margin-top: 20px;
                        }
                        
                        @keyframes spin {
                          to { transform: rotate(360deg); }
                        }
                        
                        /* Error Screen */
                        .error {
                          display: flex;
                          flex-direction: column;
                          justify-content: center;
                          align-items: center;
                          height: 100vh;
                          background-color: #0f172a;
                        }
                        
                        .error button {
                          margin-top: 20px;
                          padding: 10px 20px;
                          background-color: #3b82f6;
                          color: white;
                          border: none;
                          border-radius: 4px;
                          cursor: pointer;
                        }
                        
                        /* Main App Layout */
                        .dex-app {
                          display: flex;
                          flex-direction: column;
                          height: 100vh;
                        }
                        
                        /* Header */
                        .app-header {
                          display: flex;
                          justify-content: space-between;
                          align-items: center;
                          padding: 15px 20px;
                          background-color: #1e293b;
                          border-bottom: 1px solid #334155;
                          box-shadow: 0 2px 10px rgba(0, 0, 0, 0.3);
                        }
                        
                        .header-left h1 {
                          margin: 0;
                          font-size: 1.8rem;
                          color: #3b82f6;
                        }
                        
                        .header-right {
                          display: flex;
                          gap: 20px;
                        }
                        
                        .user-info, .wallet-info {
                          display: flex;
                          align-items: center;
                          gap: 8px;
                          background-color: #334155;
                          padding: 8px 15px;
                          border-radius: 20px;
                          font-size: 0.9rem;
                        }
                        
                        .user-info.admin {
                          background-color: #f59e0b;
                          color: #1e293b;
                        }
                        
                        /* Main Content */
                        .app-content {
                          display: flex;
                          flex: 1;
                          overflow: hidden;
                        }
                        
                        /* Sidebar */
                        .sidebar {
                          width: 300px;
                          background-color: #1e293b;
                          border-right: 1px solid #334155;
                          display: flex;
                          flex-direction: column;
                          overflow-y: auto;
                        }
                        
                        .market-overview, .wallet-info, .recent-trades {
                          padding: 20px;
                          border-bottom: 1px solid #334155;
                        }
                        
                        .market-overview h2, .wallet-info h2, .recent-trades h2 {
                          margin-top: 0;
                          margin-bottom: 15px;
                          color: #cbd5e1;
                          display: flex;
                          align-items: center;
                          gap: 10px;
                        }
                        
                        .trade-pairs {
                          list-style: none;
                          padding: 0;
                          margin: 0;
                        }
                        
                        .trade-pairs li {
                          display: flex;
                          justify-content: space-between;
                          padding: 12px 10px;
                          border-radius: 4px;
                          cursor: pointer;
                          transition: background-color 0.2s;
                        }
                        
                        .trade-pairs li:hover {
                          background-color: #334155;
                        }
                        
                        .trade-pairs li.selected {
                          background-color: #3b82f6;
                        }
                        
                        .pair-name {
                          font-weight: 500;
                        }
                        
                        .pair-price {
                          font-weight: 500;
                        }
                        
                        .change.positive {
                          color: #10b981;
                        }
                        
                        .change.negative {
                          color: #ef4444;
                        }
                        
                        .wallet-assets .asset {
                          display: flex;
                          justify-content: space-between;
                          padding: 8px 0;
                          border-bottom: 1px solid #334155;
                        }
                        
                        .wallet-assets .asset:last-child {
                          border-bottom: none;
                        }
                        
                        .recent-trades .orders-list {
                          max-height: 300px;
                          overflow-y: auto;
                        }
                        
                        .order-item {
                          padding: 10px;
                          border-bottom: 1px solid #334155;
                          background-color: #334155;
                          border-radius: 4px;
                          margin-bottom: 8px;
                        }
                        
                        .order-item:last-child {
                          border-bottom: none;
                          margin-bottom: 0;
                        }
                        
                        .order-header {
                          display: flex;
                          justify-content: space-between;
                          margin-bottom: 5px;
                        }
                        
                        .order-header .buy {
                          color: #10b981;
                        }
                        
                        .order-header .sell {
                          color: #ef4444;
                        }
                        
                        .order-status {
                          font-size: 0.8rem;
                          color: #94a3b8;
                        }
                        
                        .order-details {
                          display: flex;
                          justify-content: space-between;
                          font-size: 0.8rem;
                          color: #cbd5e1;
                        }
                        
                        /* Admin Panel */
                        .admin-panel {
                          padding: 20px;
                          border-top: 1px solid #334155;
                        }
                        
                        .admin-panel h2 {
                          margin-top: 0;
                          color: #cbd5e1;
                          display: flex;
                          align-items: center;
                          gap: 10px;
                        }
                        
                        .admin-stats {
                          display: grid;
                          grid-template-columns: repeat(2, 1fr);
                          gap: 15px;
                          margin-bottom: 20px;
                        }
                        
                        .stat-card {
                          background-color: #334155;
                          padding: 15px;
                          border-radius: 8px;
                          text-align: center;
                        }
                        
                        .stat-card h3 {
                          margin: 0 0 10px 0;
                          font-size: 1rem;
                          color: #94a3b8;
                        }
                        
                        .stat-card p {
                          margin: 0;
                          font-size: 1.2rem;
                          font-weight: 500;
                        }
                        
                        .stat-card .status {
                          color: #10b981;
                        }
                        
                        .user-management {
                          background-color: #334155;
                          padding: 15px;
                          border-radius: 8px;
                        }
                        
                        .user-management h3 {
                          margin-top: 0;
                          color: #cbd5e1;
                          display: flex;
                          align-items: center;
                          gap: 10px;
                        }
                        
                        .user-table {
                          width: 100%;
                          border-collapse: collapse;
                          color: #f1f5f9;
                        }
                        
                        .user-table th, .user-table td {
                          padding: 10px;
                          text-align: left;
                          border-bottom: 1px solid #475569;
                        }
                        
                        .user-table th {
                          color: #94a3b8;
                          font-weight: 500;
                        }
                        
                        .btn-action {
                          background: none;
                          border: none;
                          color: #94a3b8;
                          cursor: pointer;
                          margin-right: 5px;
                        }
                        
                        .btn-action:hover {
                          color: #f1f5f9;
                        }
                        
                        /* Main Trading Area */
                        .main-content {
                          flex: 1;
                          display: flex;
                          padding: 20px;
                          gap: 20px;
                          overflow: hidden;
                        }
                        
                        .trading-panel {
                          flex: 1;
                          display: flex;
                          flex-direction: column;
                          background-color: #1e293b;
                          border-radius: 8px;
                          padding: 20px;
                          box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1);
                        }
                        
                        .panel-header {
                          display: flex;
                          justify-content: space-between;
                          align-items: center;
                          margin-bottom: 20px;
                          padding-bottom: 15px;
                          border-bottom: 1px solid #334155;
                        }
                        
                        .panel-header h2 {
                          margin: 0;
                          font-size: 1.5rem;
                          color: #f1f5f9;
                        }
                        
                        .current-price {
                          font-size: 1.3rem;
                          font-weight: 500;
                        }
                        
                        .order-form {
                          background-color: #334155;
                          border-radius: 8px;
                          padding: 20px;
                          margin-bottom: 20px;
                        }
                        
                        .form-tabs {
                          display: flex;
                          margin-bottom: 20px;
                        }
                        
                        .tab {
                          flex: 1;
                          padding: 10px;
                          background-color: #475569;
                          border: none;
                          color: #cbd5e1;
                          cursor: pointer;
                          font-weight: 500;
                        }
                        
                        .tab:first-child {
                          border-top-left-radius: 4px;
                          border-bottom-left-radius: 4px;
                        }
                        
                        .tab:last-child {
                          border-top-right-radius: 4px;
                          border-bottom-right-radius: 4px;
                        }
                        
                        .tab.active {
                          background-color: #3b82f6;
                          color: white;
                        }
                        
                        .form-group {
                          margin-bottom: 15px;
                        }
                        
                        .form-group label {
                          display: block;
                          margin-bottom: 5px;
                          color: #cbd5e1;
                        }
                        
                        .form-group input {
                          width: 100%;
                          padding: 10px;
                          background-color: #1e293b;
                          border: 1px solid #475569;
                          border-radius: 4px;
                          color: #f1f5f9;
                          box-sizing: border-box;
                        }
                        
                        .form-group input:focus {
                          outline: none;
                          border-color: #3b82f6;
                        }
                        
                        .order-buttons {
                          display: flex;
                          gap: 10px;
                          margin-top: 20px;
                        }
                        
                        .btn {
                          flex: 1;
                          padding: 12px;
                          border: none;
                          border-radius: 4px;
                          font-weight: 500;
                          cursor: pointer;
                          transition: background-color 0.2s;
                        }
                        
                        .btn.buy {
                          background-color: #10b981;
                          color: white;
                        }
                        
                        .btn.sell {
                          background-color: #ef4444;
                          color: white;
                        }
                        
                        .btn.quote-btn {
                          background-color: #3b82f6;
                          color: white;
                          width: 100%;
                        }
                        
                        .btn:hover {
                          opacity: 0.9;
                        }
                        
                        .quote-section {
                          margin-top: auto;
                        }
                        
                        .quote-result {
                          margin-top: 15px;
                          padding: 15px;
                          background-color: #334155;
                          border-radius: 4px;
                          border-left: 4px solid #3b82f6;
                        }
                        
                        /* Order Book */
                        .order-book {
                          width: 350px;
                          background-color: #1e293b;
                          border-radius: 8px;
                          padding: 20px;
                          box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1);
                          display: flex;
                          flex-direction: column;
                        }
                        
                        .order-book h2 {
                          margin-top: 0;
                          margin-bottom: 20px;
                          color: #f1f5f9;
                          display: flex;
                          align-items: center;
                          gap: 10px;
                        }
                        
                        .order-book-content {
                          flex: 1;
                          display: flex;
                          flex-direction: column;
                        }
                        
                        .sell-orders, .buy-orders {
                          flex: 1;
                        }
                        
                        .order-row {
                          display: flex;
                          justify-content: space-between;
                          padding: 8px 0;
                          font-size: 0.9rem;
                        }
                        
                        .order-row .price {
                          color: #ef4444;
                        }
                        
                        .order-row .amount {
                          color: #94a3b8;
                        }
                        
                        .order-row .total {
                          color: #94a3b8;
                        }
                        
                        .current-price {
                          text-align: center;
                          padding: 15px 0;
                          font-size: 1.2rem;
                          font-weight: 500;
                          border-top: 1px solid #334155;
                          border-bottom: 1px solid #334155;
                          margin: 10px 0;
                        }
                        
                        .buy-orders .order-row .price {
                          color: #10b981;
                        }
                        
                        /* Market Data */
                        .market-data {
                          width: 300px;
                          background-color: #1e293b;
                          border-radius: 8px;
                          padding: 20px;
                          box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1);
                          display: flex;
                          flex-direction: column;
                        }
                        
                        .recent-trades-section h2 {
                          margin-top: 0;
                          margin-bottom: 20px;
                          color: #f1f5f9;
                          display: flex;
                          align-items: center;
                          gap: 10px;
                        }
                        
                        .trades-list {
                          flex: 1;
                        }
                        
                        .trade-item {
                          display: flex;
                          justify-content: space-between;
                          padding: 8px 0;
                          font-size: 0.9rem;
                          border-bottom: 1px solid #334155;
                        }
                        
                        .trade-item:last-child {
                          border-bottom: none;
                        }
                        
                        .trade-item .buy {
                          color: #10b981;
                        }
                        
                        .trade-item .sell {
                          color: #ef4444;
                        }
                        
                        /* Footer */
                        .app-footer {
                          padding: 15px 20px;
                          background-color: #1e293b;
                          border-top: 1px solid #334155;
                          text-align: center;
                          font-size: 0.9rem;
                          color: #94a3b8;
                        }
                        
                        .app-footer p {
                          margin: 5px 0;
                        }
                        
                        /* Responsive Design */
                        @media (max-width: 1200px) {
                          .sidebar {
                            width: 250px;
                          }
                          
                          .order-book, .market-data {
                            width: 300px;
                          }
                        }
                        
                        @media (max-width: 992px) {
                          .main-content {
                            flex-direction: column;
                          }
                          
                          .order-book, .market-data {
                            width: 100%;
                            order: -1;
                          }
                          
                          .sidebar {
                            width: 200px;
                          }
                        }
                        
                        @media (max-width: 768px) {
                          .app-header {
                            flex-direction: column;
                            gap: 10px;
                          }
                          
                          .header-right {
                            width: 100%;
                            justify-content: space-between;
                          }
                          
                          .sidebar {
                            display: none;
                          }
                          
                          .main-content {
                            padding: 10px;
                          }
                          
                          .trading-panel, .order-book, .market-data {
                            padding: 15px;
                          }
                        }
                        "#}
                    </style>
                </div>
            }
        },
        AppState::Error(message) => {
            html! {
                <div class="error">
                    <h1>{ "Error" }</h1>
                    <p>{ message }</p>
                    <button onclick={
                        Callback::from(move |_| {
                            // Reload the page
                            window().unwrap().location().reload().unwrap();
                        })
                    }>{ "Retry" }</button>
                </div>
            }
        }
    }
}