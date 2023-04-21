mod minting;
mod token_uri;
mod unboxing;

#[contract]
mod BoxNFT {
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

    // from contracts.ecosystem.to_briq import (
    //     getBriqAddress_,
    //     setBriqAddress_,
    use briq_protocol::ecosystem::to_briq::toBriq;

    #[view]
    fn getBriqAddress_() -> TempContractAddress {
        toBriq::get()
    }

    #[external]
    fn setBriqAddress_(address: TempContractAddress) {
        toBriq::set(address);
    }

    // from contracts.ecosystem.to_booklet import (
    //     getBookletAddress_,
    //     setBookletAddress_,
    use briq_protocol::ecosystem::to_booklet::toBooklet;

    #[view]
    fn getBookletAddress_() -> TempContractAddress {
        toBooklet::get()
    }

    #[external]
    fn setBookletAddress_(address: TempContractAddress) {
        toBooklet::set(address);
    }


    // from contracts.box_nft.minting import (
    //     mint_,
    #[external]
    fn mint_(owner: felt252, token_id: felt252, number: felt252) {
        briq_protocol::box_nft::minting::mint_(owner, token_id, number);
    }

    // from contracts.box_nft.unboxing import (
    //     unbox_,
    #[external]
    fn unbox_(owner: felt252, token_id: felt252) {
        briq_protocol::box_nft::unboxing::unbox_(owner, token_id);
    }

    // from contracts.box_nft.token_uri import (
    //     get_box_data,
    //     get_box_nb,
    //     tokenURI_,
    use briq_protocol::box_nft::token_uri;
    #[view]
    fn get_box_data(token_id: felt252) -> token_uri::BoxData {
        token_uri::get_box_data(token_id)
    }
    #[view]
    fn get_box_nb(nb: felt252) -> felt252 {
        token_uri::get_box_nb(nb)
    }
    #[view]
    fn tokenURI_(token_id: felt252) -> Array<felt252> {
        token_uri::tokenURI_(token_id)
    }


    // from contracts.library_erc1155.IERC1155 import (
    //     setApprovalForAll_,
    //     isApprovedForAll_,
    //     balanceOf_,
    //     balanceOfBatch_,
    //     safeTransferFrom_,
    //     supportsInterface,

    // from contracts.library_erc1155.IERC1155_OZ import (
    //     setApprovalForAll,
    //     isApprovedForAll,
    //     balanceOf,
    //     balanceOfBatch,
    //     safeTransferFrom,

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
    fn supportsInterface() -> bool {
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