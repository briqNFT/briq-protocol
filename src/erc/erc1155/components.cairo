use starknet::ContractAddress;
use dojo_erc::erc1155::components::{OperatorApproval};

#[derive(Component, Copy, Drop, Serde, SerdeLen)]
struct Balance {
    #[key]
    token: ContractAddress,
    #[key]
    token_id: felt252,
    #[key]
    account: ContractAddress,

    // Todo -> bitpacking?
    amount: u64,
}
