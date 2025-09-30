use rust_decimal::Decimal;
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
