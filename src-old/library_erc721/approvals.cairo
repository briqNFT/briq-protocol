#[contract]
mod Approvals {
    use briq_protocol::utils::TempContractAddress;
    use briq_protocol::utils::GetCallerAddress;
    use briq_protocol::utilities::authorization::Auth::_only;

    use traits::TryInto;
    use option::OptionTrait;
    use starknet::contract_address;

    struct Storage {
        _approval_single: LegacyMap<felt252, TempContractAddress>,
        // # approved_address aka 'operator'
        _approval_all: LegacyMap<(TempContractAddress, TempContractAddress), bool>,
    }

    use briq_protocol::library_erc721::balance::Balance;

    fn approve_nocheck_(to: TempContractAddress, token_id: felt252) {
        _approval_single::write(token_id, to);
    }

    // @external
    fn approve_(to: TempContractAddress, token_id: felt252) {
        let owner = Balance::_owner::read(token_id);

        //with_attr error_message("ERC721: cannot approve from the zero address") {
        assert(owner != 0, 'No approval from 0');

        //with_attr error_message("ERC721: approval to current owner") {
        assert(owner != to, 'No approval to owner');

        // Checks that either caller equals owner or
        // caller isApprovedForAll on behalf of owner
        _onlyApprovedAll(owner);

        _approval_single::write(token_id, to);
        return ();
    }

    // @external
    fn setApprovalForAll_(approved_address: TempContractAddress, is_approved: bool) {
        _setExplicitApprovalForAll(GetCallerAddress(), approved_address, is_approved)
    }

    fn _setExplicitApprovalForAll(on_behalf_of: TempContractAddress, approved_address: TempContractAddress, is_approved: bool) {
        // Neither of these can be 0.
        //with_attr error_message("ERC721: either the caller or operator is the zero address") {
        assert(on_behalf_of != 0, 'caller is 0');
        assert(approved_address != 0, 'operator is 0');

        // Cannot approve yourself.
        //with_attr error_message("ERC721: approve to caller") {
        assert(on_behalf_of != approved_address, 'approve to caller');

        // Make sure `is_approved` is a boolean (0 or 1)
        //with_attr error_message("ERC721: approved is not a Cairo boolean") {
        //    assert is_approved * (1 - is_approved) = 0;
        //}

        _approval_all::write((on_behalf_of, approved_address), is_approved);
    }

    // @view
    fn getApproved_(token_id: felt252) -> TempContractAddress {
        _approval_single::read(token_id)
    }

    // @view
    fn isApprovedForAll_(on_behalf_of: TempContractAddress, address: TempContractAddress) -> bool {
        _approval_all::read((on_behalf_of, address))
    }

    // ## Auth

    fn _onlyApproved(on_behalf_of: TempContractAddress, token_id: felt252) {
        let caller = GetCallerAddress();
        // You can always approve on behalf of yourself.
        if (on_behalf_of == caller) {
            return ();
        }
        if (isApprovedForAll_(on_behalf_of, caller)) {
            return ();
        }
        _only(getApproved_(token_id).try_into().unwrap());
    }

    fn _onlyApprovedAll(on_behalf_of: TempContractAddress) {
        let caller = GetCallerAddress();
        // You can always approve on behalf of yourself.
        if (caller == on_behalf_of) {
            return ();
        }
        assert(isApprovedForAll_(on_behalf_of, caller), 'Not approved for all');
    }
}
