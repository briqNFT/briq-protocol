use starknet::ContractAddress;

trait InternalTrait721<ContractState> {
    fn _owner_of(self: @ContractState, token_id: u256) -> ContractAddress;
    fn _exists(self: @ContractState, token_id: u256) -> bool;
    fn _is_approved_or_owner(
        self: @ContractState, spender: ContractAddress, token_id: u256
    ) -> bool;
    fn _approve(ref self: ContractState, to: ContractAddress, token_id: u256);
    fn _set_approval_for_all(
        ref self: ContractState,
        owner: ContractAddress,
        operator: ContractAddress,
        approved: bool
    );

    fn _transfer(
        ref self: ContractState, from: ContractAddress, to: ContractAddress, token_id: u256
    );

    fn _safe_transfer(
        ref self: ContractState,
        from: ContractAddress,
        to: ContractAddress,
        token_id: u256,
        data: Span<felt252>
    );

    fn _mint(ref self: ContractState, to: ContractAddress, token_id: u256);
    fn _burn(ref self: ContractState, token_id: u256);
    fn _safe_mint(
        ref self: ContractState, to: ContractAddress, token_id: u256, data: Span<felt252>
    );
}
