mod attributes;
mod collection;

use traits::{Into, TryInto};
use option::OptionTrait;

const COLLECTION_ID_MASK: felt252 = 0xffffffffffffffffffffffffffffffffffffffffffffffff; // 2**192 - 1;

fn get_collection_id(attribute_id: felt252) -> felt252 {
    let collection_id = Into::<felt252, u256>::into(attribute_id) & COLLECTION_ID_MASK.into();
    return collection_id.try_into().unwrap();
}
