use cosmwasm_std::{
    entry_point, to_json_binary, Binary, Deps, DepsMut, Env, MessageInfo, Response,
    StdError, StdResult,
};
use cw2::set_contract_version;
use cw_storage_plus::{Item, Map};
use serde::{Deserialize, Serialize};
use std::collections::{BTreeMap, BinaryHeap, HashMap};

// ---- Contract metadata ----
const CONTRACT_NAME: &str = "cw-router";
const CONTRACT_VERSION: &str = "0.1.0";

// ---- State ----
#[derive(Serialize, Deserialize, Clone, Debug, PartialEq)]
pub struct Config {
    pub owner: String,
}

#[derive(Serialize, Deserialize, Clone, Debug, PartialEq)]
pub struct PoolInfo {
    pub address: String,
    pub token_x: String,
    pub token_y: String,
    pub fee_bps: u16,
    pub liquidity: u128,
}

// Pathfinding structures
#[derive(Serialize, Deserialize, Clone, Debug, PartialEq)]
pub struct Route {
    pub pools: Vec<String>,
    pub tokens: Vec<String>,
    pub estimated_output: u128,
    pub price_impact: u64, // In basis points
}

#[derive(Serialize, Deserialize, Clone, Debug, PartialEq)]
pub struct TokenPair {
    pub token_a: String,
    pub token_b: String,
}

impl TokenPair {
    pub fn new(token_a: String, token_b: String) -> Self {
        // Always sort tokens to ensure consistent key
        if token_a < token_b {
            TokenPair { token_a, token_b }
        } else {
            TokenPair { token_a: token_b, token_b: token_a }
        }
    }
}

// State storage
const CONFIG: Item<Config> = Item::new("config");
const POOLS: Map<&str, PoolInfo> = Map::new("pools");
const TOKEN_PAIRS: Map<&str, Vec<String>> = Map::new("token_pairs"); // token_pair -> pool_addresses

// ---- Messages ----
#[derive(Serialize, Deserialize, Clone, Debug, PartialEq)]
pub struct InstantiateMsg {
    pub owner: String,
}

#[derive(Serialize, Deserialize, Clone, Debug, PartialEq)]
#[serde(rename_all = "snake_case")]
pub enum ExecuteMsg {
    AddPool {
        pool_address: String,
        token_x: String,
        token_y: String,
        fee_bps: u16,
        liquidity: u128,
    },
    RemovePool {
        pool_address: String,
    },
}

#[derive(Serialize, Deserialize, Clone, Debug, PartialEq)]
#[serde(rename_all = "snake_case")]
pub enum QueryMsg {
    Config {},
    Pool {
        pool_address: String,
    },
    Route {
        token_in: String,
        token_out: String,
        amount_in: u128,
    },
    PoolsForTokenPair {
        token_a: String,
        token_b: String,
    },
}

// ---- Instantiate ----
#[entry_point]
pub fn instantiate(
    deps: DepsMut,
    _env: Env,
    info: MessageInfo,
    msg: InstantiateMsg,
) -> StdResult<Response> {
    set_contract_version(deps.storage, CONTRACT_NAME, CONTRACT_VERSION)?;
    
    let config = Config {
        owner: msg.owner,
    };
    CONFIG.save(deps.storage, &config)?;
    
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
        ExecuteMsg::AddPool { pool_address, token_x, token_y, fee_bps, liquidity } => {
            execute_add_pool(deps, info, pool_address, token_x, token_y, fee_bps, liquidity)
        }
        ExecuteMsg::RemovePool { pool_address } => {
            execute_remove_pool(deps, info, pool_address)
        }
    }
}

fn execute_add_pool(
    deps: DepsMut,
    _info: MessageInfo,
    pool_address: String,
    token_x: String,
    token_y: String,
    fee_bps: u16,
    liquidity: u128,
) -> StdResult<Response> {
    // Save pool info
    let pool_info = PoolInfo {
        address: pool_address.clone(),
        token_x: token_x.clone(),
        token_y: token_y.clone(),
        fee_bps,
        liquidity,
    };
    POOLS.save(deps.storage, &pool_address, &pool_info)?;
    
    // Update token pairs mapping
    let token_pair = TokenPair::new(token_x, token_y);
    let pair_key = format!("{}-{}", token_pair.token_a, token_pair.token_b);
    
    let mut pools_for_pair = TOKEN_PAIRS.may_load(deps.storage, &pair_key)?.unwrap_or_default();
    if !pools_for_pair.contains(&pool_address) {
        pools_for_pair.push(pool_address.clone());
        TOKEN_PAIRS.save(deps.storage, &pair_key, &pools_for_pair)?;
    }
    
    Ok(Response::new()
        .add_attribute("action", "add_pool")
        .add_attribute("pool_address", pool_address))
}

fn execute_remove_pool(
    deps: DepsMut,
    _info: MessageInfo,
    pool_address: String,
) -> StdResult<Response> {
    // Load pool info to get token pair
    let pool_info = POOLS.load(deps.storage, &pool_address)?;
    
    // Remove from pools
    POOLS.remove(deps.storage, &pool_address);
    
    // Update token pairs mapping
    let token_pair = TokenPair::new(pool_info.token_x, pool_info.token_y);
    let pair_key = format!("{}-{}", token_pair.token_a, token_pair.token_b);
    
    let mut pools_for_pair = TOKEN_PAIRS.may_load(deps.storage, &pair_key)?.unwrap_or_default();
    pools_for_pair.retain(|addr| addr != &pool_address);
    
    if pools_for_pair.is_empty() {
        TOKEN_PAIRS.remove(deps.storage, &pair_key);
    } else {
        TOKEN_PAIRS.save(deps.storage, &pair_key, &pools_for_pair)?;
    }
    
    Ok(Response::new()
        .add_attribute("action", "remove_pool")
        .add_attribute("pool_address", pool_address))
}

// ---- Query ----
#[entry_point]
pub fn query(deps: Deps, _env: Env, msg: QueryMsg) -> StdResult<Binary> {
    match msg {
        QueryMsg::Config {} => {
            to_json_binary(&CONFIG.load(deps.storage)?)
        }
        QueryMsg::Pool { pool_address } => {
            to_json_binary(&POOLS.load(deps.storage, &pool_address)?)
        }
        QueryMsg::Route { token_in, token_out, amount_in } => {
            to_json_binary(&find_best_route(deps, token_in, token_out, amount_in)?)
        }
        QueryMsg::PoolsForTokenPair { token_a, token_b } => {
            let token_pair = TokenPair::new(token_a, token_b);
            let pair_key = format!("{}-{}", token_pair.token_a, token_pair.token_b);
            let pools = TOKEN_PAIRS.may_load(deps.storage, &pair_key)?.unwrap_or_default();
            to_json_binary(&pools)
        }
    }
}

// Pathfinding algorithm implementation using Dijkstra's algorithm
fn find_best_route(
    deps: Deps,
    token_in: String,
    token_out: String,
    amount_in: u128,
) -> StdResult<Route> {
    // Build graph of all pools
    let all_pools: Vec<PoolInfo> = POOLS
        .range(deps.storage, None, None, cosmwasm_std::Order::Ascending)
        .map(|item| item.map(|(_, pool)| pool))
        .collect::<Result<Vec<_>, _>>()?;
    
    // If no pools, return empty route
    if all_pools.is_empty() {
        return Ok(Route {
            pools: vec![],
            tokens: vec![],
            estimated_output: 0,
            price_impact: 0,
        });
    }
    
    // Use Dijkstra's algorithm to find the best path
    let route = dijkstra_find_path(&all_pools, &token_in, &token_out, amount_in)?;
    
    Ok(route)
}

// Dijkstra's algorithm implementation for finding the best swap route
#[derive(Debug)]
struct PathNode {
    token: String,
    amount: u128,
    pools: Vec<String>,
    tokens: Vec<String>,
    distance: u128, // Negative of amount (to use max-heap as min-heap)
}

impl PartialEq for PathNode {
    fn eq(&self, other: &Self) -> bool {
        self.distance == other.distance
    }
}

impl Eq for PathNode {}

impl PartialOrd for PathNode {
    fn partial_cmp(&self, other: &Self) -> Option<std::cmp::Ordering> {
        Some(self.cmp(other))
    }
}

impl Ord for PathNode {
    fn cmp(&self, other: &Self) -> std::cmp::Ordering {
        // Reverse comparison to make BinaryHeap a max-heap for our min-distance needs
        other.distance.cmp(&self.distance)
    }
}

fn dijkstra_find_path(
    pools: &[PoolInfo],
    start_token: &str,
    end_token: &str,
    amount_in: u128,
) -> StdResult<Route> {
    // Build adjacency list
    let mut graph: HashMap<String, Vec<&PoolInfo>> = HashMap::new();
    
    for pool in pools {
        graph.entry(pool.token_x.clone()).or_insert_with(Vec::new).push(pool);
        graph.entry(pool.token_y.clone()).or_insert_with(Vec::new).push(pool);
    }
    
    // Priority queue for Dijkstra's algorithm
    let mut pq: BinaryHeap<PathNode> = BinaryHeap::new();
    
    // Distance map to track best amounts
    let mut best_amounts: HashMap<String, u128> = HashMap::new();
    
    // Initialize with start token
    pq.push(PathNode {
        token: start_token.to_string(),
        amount: amount_in,
        pools: vec![],
        tokens: vec![start_token.to_string()],
        distance: amount_in,
    });
    best_amounts.insert(start_token.to_string(), amount_in);
    
    while let Some(current) = pq.pop() {
        // If we reached the target token, return the route
        if current.token == end_token {
            // Calculate price impact
            let price_impact = if amount_in > 0 {
                let expected_price = amount_in as f64 / current.amount as f64;
                let actual_price = 1.0; // Simplified - would need actual prices in real implementation
                ((expected_price - actual_price).abs() * 10000.0) as u64
            } else {
                0
            };
            
            return Ok(Route {
                pools: current.pools,
                tokens: current.tokens,
                estimated_output: current.amount,
                price_impact,
            });
        }
        
        // Skip if we've found a better path to this token already
        if let Some(&best_amount) = best_amounts.get(&current.token) {
            if current.amount < best_amount {
                continue;
            }
        }
        
        // Explore neighbors
        if let Some(neighbors) = graph.get(&current.token) {
            for pool in neighbors {
                let (next_token, estimated_output) = if current.token == pool.token_x {
                    (pool.token_y.clone(), estimate_swap_output(current.amount, pool.liquidity, pool.fee_bps))
                } else if current.token == pool.token_y {
                    (pool.token_x.clone(), estimate_swap_output(current.amount, pool.liquidity, pool.fee_bps))
                } else {
                    continue; // Pool doesn't contain current token
                };
                
                let new_amount = estimated_output;
                
                // If we found a better path to next_token, update it
                let should_update = match best_amounts.get(&next_token) {
                    Some(&best_amount) => new_amount > best_amount,
                    None => true,
                };
                
                if should_update {
                    best_amounts.insert(next_token.clone(), new_amount);
                    
                    let mut new_pools = current.pools.clone();
                    new_pools.push(pool.address.clone());
                    
                    let mut new_tokens = current.tokens.clone();
                    new_tokens.push(next_token.clone());
                    
                    pq.push(PathNode {
                        token: next_token,
                        amount: new_amount,
                        pools: new_pools,
                        tokens: new_tokens,
                        distance: new_amount,
                    });
                }
            }
        }
    }
    
    // No path found
    Ok(Route {
        pools: vec![],
        tokens: vec![],
        estimated_output: 0,
        price_impact: 0,
    })
}

// Simple estimation of swap output (simplified constant product formula)
fn estimate_swap_output(amount_in: u128, liquidity: u128, fee_bps: u16) -> u128 {
    if liquidity == 0 || amount_in == 0 {
        return 0;
    }
    
    // Apply fee
    let fee = (amount_in as u128) * (fee_bps as u128) / 10000;
    let amount_in_after_fee = amount_in - fee;
    
    // Simplified constant product formula: (x * y = k)
    // dy = y * dx / (x + dx)
    // For estimation, we assume equal reserves
    let reserve = liquidity / 2;
    
    if reserve + amount_in_after_fee == 0 {
        0
    } else {
        (reserve * amount_in_after_fee) / (reserve + amount_in_after_fee)
    }
}