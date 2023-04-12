
use traits::PartialOrd;
use traits::Into;
use traits::TryInto;
use option::OptionTrait;

use array::ArrayTrait;
use array::SpanTrait;

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


const high_bit_max: u128 = 0x8000000000000110000000000000000_u128;

impl ___ of TryInto::<u256, felt252> {
    fn try_into(self: u256) -> Option<felt252> {
        if self.high >= high_bit_max {
            return Option::None(());
        }
        // Only one possible value otherwise, the actual PRIME - 1;
        if self.high == high_bit_max - 1_u128 {
            if self.low > 0_u128 {
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
