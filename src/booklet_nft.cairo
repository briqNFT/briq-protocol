mod attribute;
mod minting;
mod token_uri;

#[contract]
mod BookletNFT {
    use traits::Into;
    use traits::TryInto;
    use option::OptionTrait;
    

    use briq_protocol::utils;
    use briq_protocol::utils::TempContractAddress;

    use briq_protocol::types::ShapeItem;
    use briq_protocol::types::FTSpec;

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

    #[view]
    fn getAttributesRegistryAddress_() -> TempContractAddress {
        toAttributesRegistry::get()
    }

    #[external]
    fn setAttributesRegistryAddress_(address: TempContractAddress) {
        toAttributesRegistry::set(address);
    }

    //from contracts.ecosystem.to_box import (
    //    getBoxAddress_,
    //    setBoxAddress_,
    use briq_protocol::ecosystem::to_box::toBox;

    #[view]
    fn getBoxAddress_() -> TempContractAddress {
        toBox::get()
    }

    #[external]
    fn setBoxAddress_(address: TempContractAddress) {
        toBox::set(address);
    }


    //from contracts.booklet_nft.minting import (
    //    mint_
    use briq_protocol::booklet_nft::minting;

    #[external]
    fn mint_(owner: felt252, token_id: felt252, shape_contract: felt252) {
        minting::mint_(owner, token_id, shape_contract);
    }

    //from contracts.booklet_nft.token_uri import (
    //    get_shape_contract_,
    //    get_shape_,
    //    tokenURI_,
    use briq_protocol::booklet_nft::token_uri;
    #[view]
    fn get_shape_contract_(token_id: felt252) -> felt252 {
        return token_uri::toShapeContract::get_shape_contract_(token_id);
    }

    #[view]
    fn get_shape_(token_id: felt252) -> (Array::<ShapeItem>, Array::<felt252>) {
        return token_uri::get_shape_(token_id);
    }

    #[view]
    fn tokenURI_(token_id: felt252) -> Array<felt252> {
        return token_uri::tokenURI_(token_id);
    }

    //from contracts.booklet_nft.attribute import (
    //    assign_attribute,
    //    remove_attribute,
    use briq_protocol::booklet_nft::attribute;
    #[external]
    fn assign_attribute(owner: felt252, set_token_id: felt252, attribute_id: felt252, shape: Array<ShapeItem>, fts: Array<FTSpec>, nfts: Array<felt252>) {
        attribute::assign_attribute(owner, set_token_id, attribute_id, shape, fts, nfts);
    }

    #[external]
    fn remove_attribute(owner: felt252, set_token_id: felt252, attribute_id: felt252) {
        attribute::remove_attribute(owner, set_token_id, attribute_id);
    }

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

    #[external]
    fn setApprovalForAll_(approved_address: TempContractAddress, is_approved: bool) {
        Approvals::setApprovalForAll_(approved_address, is_approved);
    }
    #[external]
    fn setApprovalForAll(operator: TempContractAddress, approved: bool) {
        Approvals::setApprovalForAll_(operator, approved);
    }

    #[view]
    fn isApprovedForAll_(on_behalf_of: TempContractAddress, address: TempContractAddress) {
        Approvals::isApprovedForAll_(on_behalf_of, address);
    }
    #[view]
    fn isApprovedForAll(account: TempContractAddress, operator: TempContractAddress) {
        Approvals::isApprovedForAll_(account, operator);
    }

    #[view]
    fn balanceOf_(owner: TempContractAddress, token_id: felt252) {
        Balance::balanceOf_(owner, token_id);
    }
    #[view]
    fn balanceOf(account: TempContractAddress, id: u256) {
        Balance::balanceOf_(account, id.try_into().unwrap());
    }

    #[view]
    fn balanceOfBatch_(owners: Array<TempContractAddress>, token_ids: Array<felt252>) {
        Balance::balanceOfBatch_(owners, token_ids);
    }
    #[view]
    fn balanceOfBatch(accounts: Array<TempContractAddress>, ids: Array<u256>) {
        Balance::balanceOfBatch_(accounts, ids.into());
    }
    
    #[external]
    fn safeTransferFrom_(sender: TempContractAddress, recipient: TempContractAddress, token_id: felt252, value: felt252, data: Array<felt252>) {
        Transferability::safeTransferFrom_(sender, recipient, token_id, value, data);
    }
    #[external]
    fn safeTransferFrom(from_: TempContractAddress, to: TempContractAddress, id: u256, amount: u256, data: Array<felt252>) {
        Transferability::safeTransferFrom_(from_, to, id.try_into().unwrap(), amount.try_into().unwrap(), data);
    }

    use briq_protocol::utilities::IERC165;
    #[view]
    fn supportsInterface(interfaceId: felt252) -> bool {
        if interfaceId == IERC165::IERC165_ID {
            return true;
        }
        if interfaceId == IERC165::IERC1155_ID {
            return true;
        }
        if interfaceId == IERC165::IERC1155_METADATA_ID {
            return true;
        }
        return false;
    }

    // URI is custom
    // Not quite OZ compliant -> I return a list of felt.
    #[view]
    fn uri(id: u256) -> Array<felt252> { //(uri_len: felt, uri: felt*) {
        tokenURI_(id.try_into().unwrap())
    }
}
