
use traits::PartialOrd;
use traits::Into;

fn felt252_le(a: felt252, b: felt252) -> bool {
    a.into() <= b.into()
}

fn felt252_lt(a: felt252, b: felt252) -> bool {
    a.into() < b.into()
}

impl feltOrd of PartialOrd::<felt252> {
    #[inline(always)]
    fn le(a: felt252, b: felt252) -> bool {
        felt252_le(a, b)
    }
    #[inline(always)]
    fn ge(a: felt252, b: felt252) -> bool {
        felt252_le(b, a)
    }
    #[inline(always)]
    fn lt(a: felt252, b: felt252) -> bool {
        felt252_lt(a, b)
    }
    #[inline(always)]
    fn gt(a: felt252, b: felt252) -> bool {
        felt252_lt(b, a)
    }
}

use array::ArrayTrait;

// Fake macro to compute gas left
// TODO: Remove when automatically handled by compiler.
#[inline(always)]
fn check_gas() {
    match gas::withdraw_gas_all(get_builtin_costs()) {
        Option::Some(_) => {},
        Option::None(_) => {
            let mut data = ArrayTrait::new();
            data.append('Out of gas');
            panic(data);
        }
    }
}