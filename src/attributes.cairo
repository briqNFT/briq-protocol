mod attributes;
mod attribute_group;

use traits::{Into, TryInto};
use option::OptionTrait;

const COLLECTION_ID_MASK: felt252 =
    0xffffffffffffffffffffffffffffffffffffffffffffffff; // 2**192 - 1;


fn get_attribute_group_id(attribute_id: felt252) -> felt252 {
    let attribute_group_id = Into::<felt252, u256>::into(attribute_id) & COLLECTION_ID_MASK.into();
    return attribute_group_id.try_into().unwrap();
}
