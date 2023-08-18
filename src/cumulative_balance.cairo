use starknet::ContractAddress;
use traits::TryInto;
use option::OptionTrait;

fn CUM_BALANCE_TOKEN() -> ContractAddress { 'cum_balance'.try_into().unwrap() }
const CB_BRIQ: felt252 = 'briq';
const CB_ATTRIBUTES: felt252 = 'attributes';
