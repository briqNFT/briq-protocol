#[contract]
mod Transferability {
    use briq_protocol::library_erc721::approvals::Approvals;
    use briq_protocol::library_erc721::balance::Balance;
    use briq_protocol::utils;

    use traits::Into;

    #[event]
    fn Transfer(from_: felt252, to_: felt252, token_id_: u256) {}

    fn _transfer(sender: felt252, recipient: felt252, token_id: felt252) {
        assert(recipient != 0, 'Bad input');
        assert(sender - recipient != 0, 'Bad input');
        assert(token_id != 0, 'Bad input');

        // Reset approval (0 cost if was 0 before on starknet I believe)
        Approvals::approve_nocheck_(0, token_id);

        let curr_owner = Balance::_owner::read(token_id);
        assert(sender == curr_owner, 'Not owner');
        Balance::_owner::write(token_id, recipient);

        Balance::_decreaseBalance(sender);
        Balance::_increaseBalance(recipient);

        Transfer(sender, recipient, token_id.into());
    }

    // @external
    fn transferFrom_(sender: felt252, recipient: felt252, token_id: felt252) {
        Approvals::_onlyApproved(sender, token_id);
        _transfer(sender, recipient, token_id);
    }
}
