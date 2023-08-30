use starknet::ContractAddress;
use traits::TryInto;
use option::OptionTrait;

fn CUM_BALANCE_TOKEN() -> ContractAddress {
    'cum_balance'.try_into().unwrap()
}

fn CB_BRIQ() -> ContractAddress {
    'briq'.try_into().unwrap()
}

fn CB_ATTRIBUTES() -> ContractAddress {
    'attributes'.try_into().unwrap()
}
