use starknet::ContractAddress;

trait InternalTrait1155<ContractState> {
    fn _is_approved_for_all_or_owner(
        self: @ContractState, from: ContractAddress, caller: ContractAddress
    ) -> bool;
    fn _set_approval_for_all(
        ref self: ContractState,
        owner: ContractAddress,
        operator: ContractAddress,
        approved: bool
    );
    fn _safe_transfer_from(
        ref self: ContractState,
        from: ContractAddress,
        to: ContractAddress,
        id: u256,
        amount: u256,
        data: Array<u8>
    );
    fn _safe_batch_transfer_from(
        ref self: ContractState,
        from: ContractAddress,
        to: ContractAddress,
        ids: Array<u256>,
        amounts: Array<u256>,
        data: Array<u8>
    );
    fn _mint(ref self: ContractState, to: ContractAddress, id: u256, amount: u256);
    fn _burn(ref self: ContractState, id: u256, amount: u256);
    fn _safe_mint(
        ref self: ContractState,
        to: ContractAddress,
        id: u256,
        amount: u256,
        data: Span<felt252>
    );
}
