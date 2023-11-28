use traits::{Into, TryInto};
use option::OptionTrait;

impl FeltBitAnd of BitAnd<felt252> {
    fn bitand(lhs: felt252, rhs: felt252) -> felt252 {
        (Into::<felt252, u256>::into(lhs) & rhs.into()).try_into().unwrap()
    }
}

fn felt252_le(lhs: felt252, rhs: felt252) -> bool {
    Into::<felt252, u256>::into(lhs) <= rhs.into()
}

fn felt252_lt(lhs: felt252, rhs: felt252) -> bool {
    Into::<felt252, u256>::into(lhs) < rhs.into()
}

impl FeltOrd of PartialOrd<felt252> {
    #[inline(always)]
    fn le(lhs: felt252, rhs: felt252) -> bool {
        felt252_le(lhs, rhs)
    }
    #[inline(always)]
    fn ge(lhs: felt252, rhs: felt252) -> bool {
        felt252_le(rhs, lhs)
    }
    #[inline(always)]
    fn lt(lhs: felt252, rhs: felt252) -> bool {
        felt252_lt(lhs, rhs)
    }
    #[inline(always)]
    fn gt(lhs: felt252, rhs: felt252) -> bool {
        felt252_lt(rhs, lhs)
    }
}

impl FeltDiv of Div<felt252> {
    fn div(lhs: felt252, rhs: felt252) -> felt252 {
        // Use u256 division as the felt_div is on the modular field
        let lhs256: u256 = lhs.into();
        let rhs256: u256 = rhs.into();
        (lhs256 / rhs256).try_into().unwrap()
    }
}
