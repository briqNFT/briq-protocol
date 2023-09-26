use starknet::ContractAddress;

#[starknet::interface]
trait MintBurn<TState> {
    fn mint(ref self: TState, owner: ContractAddress, token_id: felt252, amount: u128);
    fn burn(ref self: TState, owner: ContractAddress, token_id: felt252, amount: u128);
}
