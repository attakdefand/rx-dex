use axum::{routing::get, Json, Router};
use rust_decimal::Decimal;
use serde::Serialize;
use std::net::SocketAddr;
use tokio::net::TcpListener;

#[derive(Serialize)]
struct Quote {
    out: String,
}

async fn quote_simple() -> Json<Quote> {
    // x=1_000_000, y=500_000, dx=10_000, fee=30 bps
    let out = dex_math::cpmm_out_given_in(
        Decimal::from(1_000_000u64),
        Decimal::from(500_000u64),
        Decimal::from(10_000u64),
        30,
    )
    .unwrap();
    Json(Quote {
        out: out.to_string(),
    })
}

#[tokio::main]
async fn main() {
    let app = Router::new().route("/quote/simple", get(quote_simple));

    let addr: SocketAddr = "0.0.0.0:8081".parse().unwrap();
    let listener = TcpListener::bind(addr).await.unwrap();
    println!("quoter listening on http://{}", addr);
    axum::serve(listener, app).await.unwrap();
}
