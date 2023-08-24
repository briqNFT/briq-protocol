use starknet::storage_access::{Store, StorePacking};
use serde::Serde;
use traits::{TryInto, Into};
use option::OptionTrait;

use briq_protocol::felt_math::FeltBitAnd;

#[derive(Copy, Drop, Serde)]
struct FTSpec {
    token_id: felt252,
    qty: u128,
}


#[derive(Copy, Drop, Serde, Store)]
struct ShapeItem {
    // ASCII short string
    color: u64,
    material: u64,
    x: felt252,
    y: felt252,
    z: felt252,
}

#[derive(Copy, Drop, Serde, Store)]
struct PackedShapeItem {
    color_material: felt252,
    x_y_z: felt252,
}

const TWO_POW_64: felt252 = 0x10000000000000000;
const TWO_POW_32: felt252 = 0x100000000;

const TWO_POW_MASK: felt252 = 0xFFFFFFFFFFFFFFFF;

impl ShapePacking of StorePacking<ShapeItem, PackedShapeItem> {
    fn pack(value: ShapeItem) -> PackedShapeItem
    {
        PackedShapeItem {
            color_material: value.color.into() * TWO_POW_64 + value.material.into(),
            x_y_z: value.z + value.y * TWO_POW_32 + value.x * TWO_POW_64,
        }
    }

    fn unpack(value: PackedShapeItem) -> ShapeItem
    {
        ShapeItem {
            color: (((value.color_material & (-1 - TWO_POW_MASK))).into() / Into::<felt252, u256>::into(TWO_POW_64)).try_into().unwrap(),
            material: (value.color_material & TWO_POW_MASK).try_into().unwrap(),
            x: 0,
            y: 0,
            z: 0,
        }
    }
}
