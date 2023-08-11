
#[contract]
mod Approvals {
    use briq_protocol::utils::TempContractAddress;
    use briq_protocol::utils::GetCallerAddress;

    use briq_protocol::utils;

    #[event]
    fn ApprovalForAll(_owner: TempContractAddress, _operator: TempContractAddress, _approved: bool) {
    }

    // # approved_address is 'operator' in the spec, but I find that name rather unclear.
    struct Storage {
        _approval_all: LegacyMap<(TempContractAddress, TempContractAddress), bool>,
    }

    #[external]
    fn setApprovalForAll_(approved_address: TempContractAddress, is_approved: bool) {
        let caller = GetCallerAddress();
        _setExplicitApprovalForAll(
            caller, approved_address, is_approved
        );
        return ();
    }

    fn _setExplicitApprovalForAll(on_behalf_of: TempContractAddress, approved_address: TempContractAddress, is_approved: bool) {
        // Neither of these can be 0.
        //with_attr error_message("ERC721: either the caller or operator is the zero address") {
        //assert(on_behalf_of != 0, 'Bad caller');
        //assert(approved_address != 0, 'Bad operator');

        // Cannot approve yourself.
        //with_attr error_message("ERC721: approve to caller") {
        assert(on_behalf_of != approved_address, 'Cannot approve yourself');

        // Make sure `is_approved` is a boolean (0 or 1)
        //with_attr error_message("ERC721: approved is not a Cairo boolean") {
        //assert(is_approved * (1 - is_approved) == 0, 'non-bool approved');

        _approval_all::write((on_behalf_of, approved_address), is_approved);
        ApprovalForAll(on_behalf_of, approved_address, is_approved);
        return ();
    }

    #[view]
    fn isApprovedForAll_(on_behalf_of: TempContractAddress, address: TempContractAddress) -> bool { //(is_approved: felt252) {
        return _approval_all::read((on_behalf_of, address));
    }

    // ## Auth

    fn _onlyApprovedAll(on_behalf_of: TempContractAddress) {
        let caller = GetCallerAddress();
        // You can always approve on behalf of yourself.
        if (caller == on_behalf_of) {
            return ();
        }
        assert(isApprovedForAll_(on_behalf_of, caller), 'Not approved');
    }
}
