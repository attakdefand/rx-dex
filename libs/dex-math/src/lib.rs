use rust_decimal::Decimal;
use rust_decimal::MathematicalOps;
use rust_decimal::prelude::*;
use thiserror::Error;

#[derive(Debug, Error)]
pub enum MathError {
    #[error("insufficient liquidity")]
    InsufficientLiquidity,
    #[error("invalid input")]
    InvalidInput,
}

#[inline]
pub fn cpmm_out_given_in(
    x_reserve: Decimal,
    y_reserve: Decimal,
    dx: Decimal,
    fee_bps: i64,
) -> Result<Decimal, MathError> {
    if x_reserve <= Decimal::ZERO || y_reserve <= Decimal::ZERO || dx <= Decimal::ZERO {
        return Err(MathError::InvalidInput);
    }
    // apply fee (basis points, e.g., 30 = 0.30%)
    let fee = Decimal::from(fee_bps) / Decimal::from(10_000);
    let dx_eff = dx * (Decimal::ONE - fee);

    // dy = y - (k / (x + dx_eff))
    // where k = x * y
    let k = x_reserve * y_reserve;
    let new_x = x_reserve + dx_eff;
    let new_y = k / new_x;
    let dy = y_reserve - new_y;

    if dy <= Decimal::ZERO {
        return Err(MathError::InsufficientLiquidity);
    }
    Ok(dy)
}

/// Calculate impermanent loss given price change
/// 
/// # Arguments
/// * `initial_price` - Initial price of asset (asset_y / asset_x)
/// * `current_price` - Current price of asset (asset_y / asset_x)
/// 
/// # Returns
/// * `Decimal` - Impermanent loss as a decimal (negative value means loss)
pub fn calculate_impermanent_loss(
    initial_price: Decimal,
    current_price: Decimal,
) -> Result<Decimal, MathError> {
    if initial_price <= Decimal::ZERO || current_price <= Decimal::ZERO {
        return Err(MathError::InvalidInput);
    }
    
    // IL = 2 * sqrt(P) / (1 + P) - 1
    // Where P = current_price / initial_price
    let p = current_price / initial_price;
    let sqrt_p = p.sqrt().ok_or(MathError::InvalidInput)?;
    
    let numerator = Decimal::TWO * sqrt_p;
    let denominator = Decimal::ONE + p;
    
    if denominator == Decimal::ZERO {
        return Err(MathError::InvalidInput);
    }
    
    let il = (numerator / denominator) - Decimal::ONE;
    Ok(il)
}

/// Calculate dynamic fee based on volatility
/// 
/// # Arguments
/// * `base_fee` - Base fee in basis points
/// * `price_volatility` - Price volatility as a decimal (e.g., 0.05 for 5%)
/// * `volume_24h` - 24h trading volume
/// * `pool_liquidity` - Total pool liquidity
/// 
/// # Returns
/// * `u16` - Adjusted fee in basis points
pub fn calculate_dynamic_fee(
    base_fee: u16,
    price_volatility: Decimal,
    volume_24h: Decimal,
    pool_liquidity: Decimal,
) -> Result<u16, MathError> {
    if price_volatility < Decimal::ZERO || volume_24h < Decimal::ZERO || pool_liquidity <= Decimal::ZERO {
        return Err(MathError::InvalidInput);
    }
    
    // Base fee adjustment based on volatility
    let volatility_factor = price_volatility * Decimal::from(1000i64); // Scale factor
    let volume_factor = if pool_liquidity > Decimal::ZERO {
        volume_24h / pool_liquidity
    } else {
        Decimal::ZERO
    };
    
    // Calculate fee adjustment (in basis points)
    let fee_adjustment = (volatility_factor + volume_factor * Decimal::from(50i64)) // Scale factor
        .round()
        .to_u16()
        .unwrap_or(0);
    
    // Cap the fee adjustment to prevent excessive fees
    let max_adjustment = 50u16; // Max 0.5% adjustment
    let fee_adjustment = std::cmp::min(fee_adjustment, max_adjustment);
    
    // Ensure we don't go below 0.01% (1 bp) or above 1% (100 bp)
    let adjusted_fee = base_fee.saturating_add(fee_adjustment);
    let adjusted_fee = std::cmp::min(adjusted_fee, 100u16);
    let adjusted_fee = std::cmp::max(adjusted_fee, 1u16);
    
    Ok(adjusted_fee)
}