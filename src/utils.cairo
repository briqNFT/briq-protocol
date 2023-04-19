
use traits::PartialOrd;
use traits::Into;
use traits::TryInto;
use option::OptionTrait;

use array::ArrayTrait;
use array::SpanTrait;

fn felt252_le(lhs: felt252, rhs: felt252) -> bool {
    lhs.into() <= rhs.into()
}

fn felt252_lt(lhs: felt252, rhs: felt252) -> bool {
    lhs.into() < rhs.into()
}

impl feltOrd of PartialOrd::<felt252> {
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

// Define these traits for coding convenience.
impl FeltDiv of Div::<felt252> {
    fn div(lhs: felt252, rhs: felt252) -> felt252 {
        (lhs.into() / rhs.into()).try_into().unwrap()
    }
}

impl FeltBitAnd of BitAnd::<felt252> {
    fn bitand(lhs: felt252, rhs: felt252) -> felt252 {
        (lhs.into() & rhs.into()).try_into().unwrap()
    }
}


const high_bit_max: u128 = 0x8000000000000110000000000000000;

impl ___ of TryInto::<u256, felt252> {
    fn try_into(self: u256) -> Option<felt252> {
        if self.high >= high_bit_max {
            return Option::None(());
        }
        // Only one possible value otherwise, the actual PRIME - 1;
        if self.high == high_bit_max - 1 {
            if self.low > 0 {
                return Option::None(());
            }
        }
        return Option::Some(self.low.into() + self.high.into() * 0x100000000000000000000000000000000); // 2**128
    }
}

fn _into(mut arr: Span<u256>, mut res: Array<felt252>) -> Array<felt252> {
    check_gas();
    match arr.pop_front() {
        Option::Some(value) => {
            res.append((*value).try_into().unwrap());
            return _into(arr, res);
        },
        Option::None(_) => { return res; },
    }
}
impl ____ of Into::<Array<u256>, Array<felt252>> {
    fn into(self: Array<u256>) -> Array<felt252> {
        return _into(self.span(), ArrayTrait::new());
    }
}


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

use starknet::get_caller_address;
use starknet::ContractAddress;
use starknet::contract_address;

// TODO: Haven't figured out which I want to use yet.
type TempContractAddress = felt252;

fn GetCallerAddress() -> TempContractAddress {
    return get_caller_address().into();
}
