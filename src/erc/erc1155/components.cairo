use dojo_erc::token::erc1155::components::{ERC1155OperatorApproval};

use starknet::ContractAddress;

#[derive(Component, Copy, Drop, Serde)]
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