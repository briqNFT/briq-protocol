use starknet::storage_access::{Store, StorePacking};
use serde::Serde;

#[derive(Copy, Drop, Serde)]
struct FTSpec {
    token_id: felt252,
    qty: u128,
}


#[derive(Copy, Drop, Serde, Store)]
struct ShapeItem {
    // ASCII short string
    color: felt252,
    material: u64,
    x: felt252,
    y: felt252,
    z: felt252,
}

#[derive(Copy, Drop, Serde, Store)]
struct PackedShape {
}

impl ShapePacking of StorePacking<ShapeItem, PackedShape> {
    fn pack(value: ShapeItem) -> PackedShape
    {
        PackedShape {
        }
    }

    fn unpack(value: PackedShape) -> ShapeItem
    {
        ShapeItem {
            color: 'toto',
            material: 0,
            x: 0,
            y: 0,
            z: 0,
        }
    }
}
