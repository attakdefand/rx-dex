use dex_math::cpmm_out_given_in;
use rust_decimal::Decimal;

#[test]
fn non_negative_output_basic() {
    let out = cpmm_out_given_in(
        Decimal::from(1_000_000u64),
        Decimal::from(800_000u64),
        Decimal::from(10_000u64),
        30,
    )
    .unwrap();
    assert!(out > Decimal::ZERO);
}

#[test]
fn more_input_more_output_monotonic() {
    let small = cpmm_out_given_in(
        Decimal::from(1_000_000u64),
        Decimal::from(800_000u64),
        Decimal::from(1_000u64),
        30,
    )
    .unwrap();
    let big = cpmm_out_given_in(
        Decimal::from(1_000_000u64),
        Decimal::from(800_000u64),
        Decimal::from(10_000u64),
        30,
    )
    .unwrap();
    assert!(big > small);
}
