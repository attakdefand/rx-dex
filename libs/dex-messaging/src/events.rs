//! Event definitions for the DEX messaging system

use serde::{Deserialize, Serialize};

#[derive(Serialize, Deserialize, Debug, Clone)]
pub struct OrderEvent {
    pub order_id: String,
    pub user_id: String,
    pub pair: String,
    pub side: String,
    pub price: String,
    pub amount: String,
    pub timestamp: String,
}

#[derive(Serialize, Deserialize, Debug, Clone)]
pub struct TradeEvent {
    pub trade_id: String,
    pub order_id: String,
    pub maker_order_id: String,
    pub taker_order_id: String,
    pub pair: String,
    pub price: String,
    pub amount: String,
    pub timestamp: String,
}

#[derive(Serialize, Deserialize, Debug, Clone)]
pub struct PriceUpdateEvent {
    pub pair: String,
    pub price: String,
    pub timestamp: String,
}

#[derive(Serialize, Deserialize, Debug, Clone)]
pub struct UserBalanceEvent {
    pub user_id: String,
    pub asset: String,
    pub balance: String,
    pub timestamp: String,
}