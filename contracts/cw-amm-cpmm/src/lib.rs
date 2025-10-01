use cosmwasm_std::{
    entry_point, to_json_binary, BankMsg, Binary, Coin, Deps, DepsMut, Env, MessageInfo, Response,
    StdError, StdResult, Uint128,
};
use cw2::set_contract_version;
use cw_storage_plus::Item;

// ---- Contract metadata ----
const CONTRACT_NAME: &str = "cw-amm-cpmm";
const CONTRACT_VERSION: &str = "0.2.0"; // Updated version

// ---- State ----
#[derive(serde::Serialize, serde::Deserialize, Clone, Debug, PartialEq)]
pub struct Pool {
    pub token_x: String, // denom or cw20 address (simplified for now)
    pub token_y: String,
    pub fee_bps: u16, // base fee in basis points
    pub x_reserve: Uint128,
    pub y_reserve: Uint128,
    // For dynamic fees
    pub total_volume: Uint128,
}

const POOL: Item<Pool> = Item::new("pool");

// ---- Messages ----
#[derive(serde::Serialize, serde::Deserialize, Clone, Debug, PartialEq)]
pub struct InstantiateMsg {
    pub token_x: String,
    pub token_y: String,
    pub fee_bps: u16,
}

#[derive(serde::Serialize, serde::Deserialize, Clone, Debug, PartialEq)]
#[serde(rename_all = "snake_case")]
pub enum ExecuteMsg {
    ProvideLiquidity { x: Uint128, y: Uint128 },
    SwapXForY { dx: Uint128, min_dy: Uint128 },
    SwapYForX { dy: Uint128, min_dx: Uint128 },
}

#[derive(serde::Serialize, serde::Deserialize, Clone, Debug, PartialEq)]
#[serde(rename_all = "snake_case")]
pub enum QueryMsg {
    Pool {},
}

// ---- Instantiate ----
#[entry_point]
pub fn instantiate(
    deps: DepsMut,
    _env: Env,
    _info: MessageInfo,
    msg: InstantiateMsg,
) -> StdResult<Response> {
    set_contract_version(deps.storage, CONTRACT_NAME, CONTRACT_VERSION)?;
    let pool = Pool {
        token_x: msg.token_x,
        token_y: msg.token_y,
        fee_bps: msg.fee_bps,
        x_reserve: Uint128::zero(),
        y_reserve: Uint128::zero(),
        total_volume: Uint128::zero(),
    };
    POOL.save(deps.storage, &pool)?;
    Ok(Response::new().add_attribute("method", "instantiate"))
}

// ---- Execute ----
#[entry_point]
pub fn execute(
    deps: DepsMut,
    _env: Env,
    info: MessageInfo,
    msg: ExecuteMsg,
) -> StdResult<Response> {
    match msg {
        ExecuteMsg::ProvideLiquidity { x, y } => {
            execute_provide_liquidity(deps, info, x, y)
        }
        ExecuteMsg::SwapXForY { dx, min_dy } => {
            execute_swap_x_for_y(deps, info, dx, min_dy)
        }
        ExecuteMsg::SwapYForX { dy, min_dx } => {
            execute_swap_y_for_x(deps, info, dy, min_dx)
        }
    }
}

fn execute_provide_liquidity(
    deps: DepsMut,
    info: MessageInfo,
    x: Uint128,
    y: Uint128,
) -> StdResult<Response> {
    let mut pool = POOL.load(deps.storage)?;
    // naive native-coin funding; production will use CW20 hooks etc.
    let rx = info
        .funds
        .iter()
        .find(|c| c.denom == pool.token_x)
        .map(|c| c.amount)
        .unwrap_or_default();
    let ry = info
        .funds
        .iter()
        .find(|c| c.denom == pool.token_y)
        .map(|c| c.amount)
        .unwrap_or_default();

    if rx < x || ry < y {
        return Err(StdError::generic_err("insufficient funds sent"));
    }

    pool.x_reserve += x;
    pool.y_reserve += y;
    POOL.save(deps.storage, &pool)?;
    Ok(Response::new().add_attribute("provide", format!("{x}/{y}")))
}

fn execute_swap_x_for_y(
    deps: DepsMut,
    info: MessageInfo,
    dx: Uint128,
    min_dy: Uint128,
) -> StdResult<Response> {
    let mut pool = POOL.load(deps.storage)?;
    use rust_decimal::prelude::ToPrimitive;
    use rust_decimal::Decimal;

    let x = Decimal::from(pool.x_reserve.u128());
    let y = Decimal::from(pool.y_reserve.u128());
    let dx_dec = Decimal::from(dx.u128());

    // Calculate dynamic fee based on volume
    let fee_bps = calculate_dynamic_fee(&pool, dx);
    
    let dy_dec = dex_math::cpmm_out_given_in(x, y, dx_dec, fee_bps as i64)
        .map_err(|e| StdError::generic_err(e.to_string()))?;
    let dy_u128 = dy_dec
        .to_u128()
        .ok_or_else(|| StdError::generic_err("overflow"))?;
    let dy = Uint128::from(dy_u128);

    if dy < min_dy {
        return Err(StdError::generic_err("slippage"));
    }

    pool.x_reserve += dx;
    pool.y_reserve = pool
        .y_reserve
        .checked_sub(dy)
        .map_err(|_| StdError::generic_err("underflow"))?;
    // Update volume for dynamic fee calculation
    pool.total_volume = pool.total_volume.checked_add(dx)?;
    POOL.save(deps.storage, &pool)?;

    let send = BankMsg::Send {
        to_address: info.sender.to_string(),
        amount: vec![Coin {
            denom: pool.token_y.clone(),
            amount: dy,
        }],
    };

    Ok(Response::new()
        .add_message(send)
        .add_attribute("swap_x_for_y", dy.to_string()))
}

fn execute_swap_y_for_x(
    deps: DepsMut,
    info: MessageInfo,
    dy: Uint128,
    min_dx: Uint128,
) -> StdResult<Response> {
    let mut pool = POOL.load(deps.storage)?;
    use rust_decimal::prelude::ToPrimitive;
    use rust_decimal::Decimal;

    let x = Decimal::from(pool.x_reserve.u128());
    let y = Decimal::from(pool.y_reserve.u128());
    let dy_dec = Decimal::from(dy.u128());

    // Calculate dynamic fee based on volume
    let fee_bps = calculate_dynamic_fee(&pool, dy);

    // Invert reserves to reuse "out_given_in"
    let dx_dec = dex_math::cpmm_out_given_in(y, x, dy_dec, fee_bps as i64)
        .map_err(|e| StdError::generic_err(e.to_string()))?;
    let dx_u128 = dx_dec
        .to_u128()
        .ok_or_else(|| StdError::generic_err("overflow"))?;
    let dx = Uint128::from(dx_u128);

    if dx < min_dx {
        return Err(StdError::generic_err("slippage"));
    }

    pool.y_reserve += dy;
    pool.x_reserve = pool
        .x_reserve
        .checked_sub(dx)
        .map_err(|_| StdError::generic_err("underflow"))?;
    // Update volume for dynamic fee calculation
    pool.total_volume = pool.total_volume.checked_add(dy)?;
    POOL.save(deps.storage, &pool)?;

    let send = BankMsg::Send {
        to_address: info.sender.to_string(),
        amount: vec![Coin {
            denom: pool.token_x.clone(),
            amount: dx,
        }],
    };

    Ok(Response::new()
        .add_message(send)
        .add_attribute("swap_y_for_x", dx.to_string()))
}

// Helper function to calculate dynamic fees based on volume
fn calculate_dynamic_fee(pool: &Pool, trade_amount: Uint128) -> u16 {
    // Simple dynamic fee model based on trade size relative to pool size
    let base_fee = pool.fee_bps;
    
    // If trade amount is > 1% of pool reserve, increase fee
    let reserve = std::cmp::max(pool.x_reserve, pool.y_reserve);
    if !reserve.is_zero() && !trade_amount.is_zero() {
        // Calculate trade_amount * 100 / reserve using u128 arithmetic
        let trade_amount_u128 = trade_amount.u128();
        let reserve_u128 = reserve.u128();
        
        if reserve_u128 > 0 {
            // To avoid overflow, we do the calculation carefully
            let trade_ratio = trade_amount_u128.saturating_mul(100) / reserve_u128;
            if trade_ratio > 1 {
                // Increase fee by the trade ratio (capped)
                let fee_increase = std::cmp::min(trade_ratio, 10) as u16; // Cap at 10bps increase
                return base_fee.saturating_add(fee_increase);
            }
        }
    }
    
    base_fee
}

// ---- Query ----
#[entry_point]
pub fn query(deps: Deps, _env: Env, msg: QueryMsg) -> StdResult<Binary> {
    match msg {
        QueryMsg::Pool {} => {
            let pool = POOL.load(deps.storage)?;
            to_json_binary(&pool)
        }
    }
}