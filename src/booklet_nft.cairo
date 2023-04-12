#[contract]
mod BookletNFT {
    use traits::Into;
    use traits::TryInto;
    use option::OptionTrait;
    

    use briq_protocol::utils;
    use briq_protocol::utils::TempContractAddress;


    //from contracts.upgrades.upgradable_mixin import (
    //    getAdmin_,
    //    getImplementation_,
    //    upgradeImplementation_,
    //    setRootAdmin_,
    //)

    // TODO
    

    //from contracts.ecosystem.to_attributes_registry import (
    //    getAttributesRegistryAddress_,
    //    setAttributesRegistryAddress_,
    use briq_protocol::ecosystem::to_attributes_registry::toAttributesRegistry;

    fn getAttributesRegistryAddress_() -> TempContractAddress {
        toAttributesRegistry::get()
    }

    fn setAttributesRegistryAddress_(address: TempContractAddress) {
        toAttributesRegistry::set(address);
    }

    //from contracts.ecosystem.to_box import (
    //    getBoxAddress_,
    //    setBoxAddress_,
    use briq_protocol::ecosystem::to_box::toBox;

    fn getBoxAddress_() -> TempContractAddress {
        toBox::get()
    }

    fn setBoxAddress_(address: TempContractAddress) {
        toBox::set(address);
    }


    //from contracts.booklet_nft.minting import (
    //    mint_

    //from contracts.booklet_nft.token_uri import (
    //    get_shape_contract_,
    //    get_shape_,
    //    tokenURI_,

    //from contracts.booklet_nft.attribute import (
    //    assign_attribute,
    //    remove_attribute,


    // TODO


    //from contracts.library_erc1155.IERC1155 import (
    //    setApprovalForAll_,
    //    isApprovedForAll_,
    //    balanceOf_,
    //    balanceOfBatch_,
    //    safeTransferFrom_,
    //    supportsInterface,

    //from contracts.library_erc1155.IERC1155_OZ import (
    //    setApprovalForAll,
    //    isApprovedForAll,
    //    balanceOf,
    //    balanceOfBatch,
    //    safeTransferFrom,

    use briq_protocol::library_erc1155::approvals::Approvals;
    use briq_protocol::library_erc1155::balance::Balance;
    use briq_protocol::library_erc1155::transferability::Transferability;

    fn setApprovalForAll_(approved_address: TempContractAddress, is_approved: bool) {
        Approvals::setApprovalForAll_(approved_address, is_approved);
    }
    fn setApprovalForAll(operator: TempContractAddress, approved: bool) {
        Approvals::setApprovalForAll_(operator, approved);
    }

    fn isApprovedForAll_(on_behalf_of: TempContractAddress, address: TempContractAddress) {
        Approvals::isApprovedForAll_(on_behalf_of, address);
    }
    fn isApprovedForAll(account: TempContractAddress, operator: TempContractAddress) {
        Approvals::isApprovedForAll_(account, operator);
    }

    fn balanceOf_(owner: TempContractAddress, token_id: felt252) {
        Balance::balanceOf_(owner, token_id);
    }
    fn balanceOf(account: TempContractAddress, id: u256) {
        Balance::balanceOf_(account, id.try_into().unwrap());
    }

    fn balanceOfBatch_(owners: Array<TempContractAddress>, token_ids: Array<felt252>) {
        Balance::balanceOfBatch_(owners, token_ids);
    }
    fn balanceOfBatch(accounts: Array<TempContractAddress>, ids: Array<u256>) {
        Balance::balanceOfBatch_(accounts, ids.into());
    }
    
    fn safeTransferFrom_(sender: TempContractAddress, recipient: TempContractAddress, token_id: felt252, value: felt252, data: Array<felt252>) {
        Transferability::safeTransferFrom_(sender, recipient, token_id, value, data);
    }
    fn safeTransferFrom(from_: TempContractAddress, to: TempContractAddress, id: u256, amount: u256, data: Array<felt252>) {
        Transferability::safeTransferFrom_(from_, to, id.try_into().unwrap(), amount.try_into().unwrap(), data);
    }

    fn supportsInterface() -> bool {
        // TODO
        false
    }

    // URI is custom
    // Not quite OZ compliant -> I return a list of felt.
    //#[view]
    //fn uri(id: u256) -> Array<felt> { //(uri_len: felt, uri: felt*) {
    //    return tokenURI_(token_id=tid);
    //}    
}
