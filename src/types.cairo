#[derive(Copy, Drop, Serde)]
struct FTSpec {
    token_id: felt252,
    qty: u128,
}


#[derive(Copy, Drop, Serde)]
struct ShapeItem {
    // ASCII short string
    color: felt252,
    material: u64,
    x: felt252,
    y: felt252,
    z: felt252,
}
