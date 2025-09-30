use cw_multi_test::{App, Contract, ContractWrapper};
use cosmwasm_std::Uint128;
use cw_amm_cpmm::{InstantiateMsg, ExecuteMsg, QueryMsg, Pool};

fn contract() -> Box<dyn Contract<cosmwasm_std::Empty>> {
    let c = ContractWrapper::new(
        cw_amm_cpmm::execute,
        cw_amm_cpmm::instantiate,
        cw_amm_cpmm::query,
    );
    Box::new(c)
}

#[test]
fn instantiate_and_provide() {
    let mut app = App::default();
    let code_id = app.store_code(contract());

    let addr = app.instantiate_contract(
        code_id,
        app.api().addr_make("owner"),
        &InstantiateMsg { token_x: "ux".into(), token_y: "uy".into(), fee_bps: 30 },
        &[],
        "pool",
        None,
    ).unwrap();

    app.execute_contract(
        app.api().addr_make("lp1"),
        addr.clone(),
        &ExecuteMsg::ProvideLiquidity { x: Uint128::new(1_000_000), y: Uint128::new(2_000_000) },
        &[],
    ).unwrap();

    let pool: Pool = app.wrap().query_wasm_smart(addr, &QueryMsg::Pool{}).unwrap();
    assert_eq!(pool.x_reserve, Uint128::new(1_000_000));
    assert_eq!(pool.y_reserve, Uint128::new(2_000_000));
}
