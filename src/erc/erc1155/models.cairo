use presets::erc1155::erc1155::models::{ERC1155OperatorApproval, erc_1155_operator_approval};

use starknet::ContractAddress;

#[derive(Model, Copy, Drop, Serde)]
struct ERC1155Balance {
    #[key]
    token: ContractAddress,
    #[key]
    account: ContractAddress,
    #[key]
    id: felt252,
    amount: u128
}

use dojo::world::{IWorldDispatcher, IWorldDispatcherTrait};

fn increase_balance(
    world: IWorldDispatcher,
    token: ContractAddress,
    account: ContractAddress,
    id: felt252,
    amount: u128)
{
    let balance = get!(world, (token, account, id), ERC1155Balance);
    set!(world, ERC1155Balance { token, account, id, amount: balance.amount + amount });
}
fn decrease_balance(
    world: IWorldDispatcher,
    token: ContractAddress,
    account: ContractAddress,
    id: felt252,
    amount: u128)
{
    let balance = get!(world, (token, account, id), ERC1155Balance);
    set!(world, ERC1155Balance { token, account, id, amount: balance.amount - amount });
}
