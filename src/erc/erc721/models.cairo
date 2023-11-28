use starknet::ContractAddress;

use presets::erc721::models::{ERC721OperatorApproval, erc_721_operator_approval};

#[derive(Model, Copy, Drop, Serde)]
struct ERC721Owner {
    #[key]
    token: ContractAddress,
    #[key]
    token_id: felt252,
    address: ContractAddress
}

#[derive(Model, Copy, Drop, Serde)]
struct ERC721Balance {
    #[key]
    token: ContractAddress,
    #[key]
    account: ContractAddress,
    amount: u128,
}

#[derive(Model, Copy, Drop, Serde)]
struct ERC721TokenApproval {
    #[key]
    token: ContractAddress,
    #[key]
    token_id: felt252,
    address: ContractAddress,
}


use dojo::world::{IWorldDispatcher, IWorldDispatcherTrait};

fn increase_balance(
    world: IWorldDispatcher,
    token: ContractAddress,
    account: ContractAddress,
    amount: u128)
{
    let balance = get!(world, (token, account), ERC721Balance);
    set!(world, ERC721Balance { token, account, amount: balance.amount + amount });
}
fn decrease_balance(
    world: IWorldDispatcher,
    token: ContractAddress,
    account: ContractAddress,
    amount: u128)
{
    let balance = get!(world, (token, account), ERC721Balance);
    set!(world, ERC721Balance { token, account, amount: balance.amount - amount });
}
