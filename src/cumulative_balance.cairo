use starknet::ContractAddress;
use traits::TryInto;
use option::OptionTrait;

fn CUM_BALANCE_TOKEN() -> ContractAddress {
    'cum_balance'.try_into().unwrap()
}

fn CB_BRIQ() -> felt252 {
    'briq'
}

fn CB_ATTRIBUTES() -> felt252 {
    'attributes'
}
