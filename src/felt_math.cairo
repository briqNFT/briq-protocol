use traits::{Into, TryInto};
use option::OptionTrait;

impl feltBitAnd of BitAnd<felt252> {
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

impl feltOrd of PartialOrd<felt252> {
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


fn felt252_div(lhs: felt252, rhs: felt252) -> felt252 {
    let l:u256 = lhs.into();
    let r:u256 = rhs.into();
    (l/r).try_into().unwrap()
}