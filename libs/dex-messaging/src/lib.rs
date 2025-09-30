//! Messaging infrastructure for distributed RX-DEX
//!
//! This library provides abstractions for:
//! - Event publishing/subscribing
//! - Message serialization
//! - Queue management

pub mod events;
pub mod publisher;
pub mod subscriber;

pub use events::*;
pub use publisher::*;
pub use subscriber::*;