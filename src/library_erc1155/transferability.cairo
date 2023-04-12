#[contract]
mod Transferability {
    use traits::Into;

    use briq_protocol::utils::TempContractAddress;
    use briq_protocol::utils::GetCallerAddress;

    use briq_protocol::library_erc1155::balance::Balance;
    use briq_protocol::library_erc1155::approvals::Approvals;

    #[event]
    fn TransferSingle(_operator: TempContractAddress, _from: TempContractAddress, _to: TempContractAddress, _id: u256, _value: u256) {
    }

    #[event]
    fn TransferBatch(
        _operator: TempContractAddress,
        _from: TempContractAddress,
        _to: TempContractAddress,
        _ids: Array<u256>,
        _values: Array<u256>,
    ) {
    }

    fn _transfer(
        sender: TempContractAddress, recipient: TempContractAddress, token_id: felt252, value: felt252
    ) {
        assert(sender != 0, 'Bad input');
        assert(recipient != 0, 'Bad input');
        assert(sender - recipient != 0, 'Bad input');
        assert(token_id != 0, 'Bad input');
        assert(value != 0, 'Bad input');

        // TODO: implement detailled approval?
        // Reset approval (0 cost if was 0 before on starknet I believe)
        // let (caller) = get_caller_address()
        // let (approved_value) = ERC1155_approvals.getApproved_(sender, token_id, caller)
        // ERC1155_approvals.approve_nocheck_(0, token_id)

        Balance::_decreaseBalance(sender, token_id, value);
        Balance::_increaseBalance(recipient, token_id, value);

        TransferSingle(GetCallerAddress(), sender, recipient, token_id.into(), value.into());

        return ();
    }

    fn _transfer_burnable(
        sender: TempContractAddress, recipient: TempContractAddress, token_id: felt252, value: felt252
    ) {
        assert(sender != 0, 'Bad input');
        assert(token_id != 0, 'Bad input');
        assert(value != 0, 'Bad input');

        // TODO: implement detailled approval?
        // Reset approval (0 cost if was 0 before on starknet I believe)
        // let (caller) = get_caller_address()
        // let (approved_value) = ERC1155_approvals.getApproved_(sender, token_id, caller)
        // ERC1155_approvals.approve_nocheck_(0, token_id)

        Balance::_decreaseBalance(sender, token_id, value);
        Balance::_increaseBalance(recipient, token_id, value);

        TransferSingle(GetCallerAddress(), sender, recipient, token_id.into(), value.into());

        return ();
    }

    // @external
    fn safeTransferFrom_(
        sender: TempContractAddress, recipient: TempContractAddress, token_id: felt252, value: felt252, data: Array<felt252>
    ) {
        // TODO -> support detailed approvals.
        Approvals::_onlyApprovedAll(sender);

        _transfer(sender, recipient, token_id, value);

        // TODO: called the receiver fntion. I'm not entirely sure how to handle accounts yet...

        return ();
    }
}
