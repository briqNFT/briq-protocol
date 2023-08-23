const BRIQ_FACTORY_CONFIG_ID: felt252 = 69;
const BRIQ_FACTORY_STORE_ID: felt252 = 420;

// 10**18
fn DECIMALS() -> felt252 {
    1000000000000000000
}

// Arbitrary inflection point below which to use the lower_* curve
fn INFLECTION_POINT() -> felt252 {
    400000 * DECIMALS()
}
// Slope: Buying 100 000 briqs increases price per briq by 0.00001
fn SLOPE() -> felt252 {
    100000000 // 10**8
}

// Computed to hit the inflection point at 0.00003 per briq
fn RAW_FLOOR() -> felt252 {
    -1 * 10000000000000 // - 10**13
}

// Actual floor price of the briqs = 0.0001
fn LOWER_FLOOR() -> felt252 {
    10000000000000 //  10**13
}

// Computed to hit the inflection point at 0.00003 per briq
fn LOWER_SLOPE() -> felt252 {
    consteval_int!(5 * 10000000) //  5 * 10**7
}

// decay: for each second, reduce the price by so many wei. Computed to hit 200K per year.
fn DECAY_PER_SECOND() -> felt252 {
    6337791082068820
}

fn SURGE_SLOPE() -> felt252 {
    100000000 // 10**8
}

fn MINIMAL_SURGE() -> felt252 {
    250000 * DECIMALS()
}

fn SURGE_DECAY_PER_SECOND() -> felt252 {
    4134 * 100000000000000 // 4134 * 10**14 : Decays over a week
}

fn MIN_PURCHASE() -> felt252 {
    9
}

fn BRIQ_MATERIAL() -> felt252 {
    1
}
