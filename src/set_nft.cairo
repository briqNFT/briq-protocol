mod assembly;
mod token_uri;

#[contract]
mod Set {
    use briq_protocol::utils;
    use briq_protocol::types::FTSpec;
    use briq_protocol::types::ShapeItem;

    use briq_protocol::utils::TempContractAddress;

    //from contracts.upgrades.upgradable_mixin import (
    //    getAdmin_,
    //    getImplementation_,
    //    upgradeImplementation_,
    //    setRootAdmin_,
    
    // TODO

    //from contracts.ecosystem.to_briq import (
    //    getBriqAddress_,
    //    setBriqAddress_,
    use briq_protocol::ecosystem::to_briq::toBriq;

    #[view]
    fn getBriqAddress_() -> TempContractAddress {
        toBriq::get()
    }

    #[external]
    fn setBriqAddress_(address: TempContractAddress) {
        toBriq::set(address);
    }

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



    //from contracts.set_nft.token_uri import tokenURI_
    use briq_protocol::set_nft::token_uri;
    
    #[view]
    fn tokenURI_(token_id: felt252) -> Array<felt252> {
        token_uri::tokenURI_(token_id)
    }

    //from contracts.set_nft.assembly import assemble_, disassemble_
    use briq_protocol::set_nft::assembly;

    #[external]
    fn assemble_(
            owner: felt252,
            token_id_hint: felt252,
            name: Array<felt252>,
            description: Array<felt252>,
            fts: Array<FTSpec>,
            nfts: Array<felt252>,
            shape: Array<ShapeItem>,
            attributes: Array<felt252>) {
        // The name/description is unused except to have them show up in calldata.
        assembly::assemble_(owner, token_id_hint, fts, nfts, shape, attributes);
    }
    #[external]
    fn disassemble_(
            owner: felt252,
            token_id: felt252,
            fts: Array<FTSpec>,
            nfts: Array<felt252>,
            attributes: Array<felt252>) {
        assembly::disassemble_(owner, token_id, fts, nfts, attributes);
    }

    //###############
    // # Metadata extension
    //###############

    #[view]
    fn name() -> felt252 {
        'briq'
    }

    #[view]
    fn symbol() -> felt252 {
        'briq'
    }

    //###############
    // # ERC 721 interface
    //###############

    //from contracts.library_erc721.IERC721 import (
    //    approve_,
    //    setApprovalForAll_,
    //    getApproved_,
    //    isApprovedForAll_,
    //    ownerOf_,
    //    balanceOf_,
    //    balanceDetailsOf_,
    //    tokenOfOwnerByIndex_,
    //    supportsInterface,

    //from contracts.library_erc721.IERC721_enumerable import (
    //    transferFrom_,
    use briq_protocol::library_erc721::approvals::Approvals;
    use briq_protocol::library_erc721::balance::Balance;
    use briq_protocol::library_erc721::transferability::Transferability;

    #[external]
    fn approve_(to: felt252, token_id: felt252) {
        return Approvals::approve_(to, token_id);
    }

    #[external]
    fn setApprovalForAll_(approved_address: felt252, is_approved: bool) {
        return Approvals::setApprovalForAll_(approved_address, is_approved);
    }

    #[view]
    fn getApproved_(token_id: felt252) -> felt252 {
        return Approvals::getApproved_(token_id);
    }

    #[view]
    fn isApprovedForAll_(on_behalf_of: felt252, address: felt252) -> bool {
        return Approvals::isApprovedForAll_(on_behalf_of, address);
    }

    #[view]
    fn ownerOf_(token_id: felt252) -> felt252 {
        return Balance::ownerOf_(token_id);
    }

    #[view]
    fn balanceOf_(owner: felt252) -> felt252 {
        return Balance::balanceOf_(owner);
    }

    use briq_protocol::briq::balance_enumerability::BalanceEnum;
    #[view]
    fn balanceDetailsOf_(owner: felt252) -> Array<felt252> {
        BalanceEnum::materialsOf(owner)
    }

    #[view]
    fn tokenOfOwnerByIndex_(owner: felt252, index: felt252) -> felt252 {
        return BalanceEnum::_material_by_owner::read((owner, index));
    }

    #[external]
    fn transferFrom_(sender: felt252, recipient: felt252, token_id: felt252) {
        return Transferability::transferFrom_(sender, recipient, token_id);
    }

    use briq_protocol::utilities::IERC165;
    #[view]
    fn supportsInterface(interfaceId: felt252) -> bool {
        if interfaceId == IERC165::IERC165_ID {
            return true;
        }
        if interfaceId == IERC165::IERC721_ID {
            return true;
        }
        if interfaceId == IERC165::IERC721_METADATA_ID {
            return true;
        }
        return false;
    }
}
