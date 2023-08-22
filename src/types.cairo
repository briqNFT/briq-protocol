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
struct PackedShapeItem {
    color: felt252
}

impl ShapePacking of StorePacking<ShapeItem, PackedShapeItem> {
    fn pack(value: ShapeItem) -> PackedShapeItem
    {
        PackedShapeItem {
            color: 'toto'
        }
    }

    fn unpack(value: PackedShapeItem) -> ShapeItem
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
