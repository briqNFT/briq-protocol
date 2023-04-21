mod balance_enumerability;
mod minting;
mod transferability;

#[contract]
mod Briq {
    use briq_protocol::types::FTSpec;
    use briq_protocol::utils::TempContractAddress;

    //from contracts.upgrades.upgradable_mixin import (
    //    getAdmin_,
    //    getImplementation_,
    //    upgradeImplementation_,
    //    setRootAdmin_,
    
    // TODO

    //from contracts.briq.balance_enumerability import (
    //    ownerOf_,
    //    balanceOfMaterial_,
    //    balanceOfMaterials_,
    //    balanceDetailsOfMaterial_,
    //    materialsOf_,
    //    fullBalanceOf_,
    //    tokenOfOwnerByIndex_,
    //    totalSupplyOfMaterial_,
    use briq_protocol::briq::balance_enumerability::BalanceEnum;
    #[view]
    fn balanceOfMaterials(owner: felt252, materials: Array<felt252>) -> Array<felt252> {
        BalanceEnum::balanceOfMaterials(owner, materials)
    }
    #[view]
    fn materialsOf(owner: felt252) -> Array<felt252> {
        BalanceEnum::materialsOf(owner)
    }
    #[view]
    fn fullBalanceOf(owner: felt252) -> Array<FTSpec> {
        BalanceEnum::fullBalanceOf(owner)
    }

    //from contracts.briq.minting import mintFT_, mintOneNFT_
    #[external]
    fn mintFT_(owner: felt252, material: felt252, qty: felt252) {
        briq_protocol::briq::minting::mintFT_(owner, material, qty)
    }

    //from contracts.briq.transferability import (
    //    transferFT_,
    //    transferOneNFT_,
    //    transferNFT_,
    use briq_protocol::briq::transferability;
    #[external]
    fn transferFT_(sender: felt252, recipient: felt252, material: felt252, qty: felt252) {
        transferability::transferFT_(sender, recipient, material, qty)
    }

    //from contracts.briq.convert_mutate import (
    //    mutateFT_,
    //    mutateOneNFT_,
    //    convertOneToFT_,
    //    convertToFT_,
    //    convertOneToNFT_,
    //)

    //from contracts.ecosystem.to_set import (getSetAddress_, setSetAddress_)
    use briq_protocol::ecosystem::to_set::toSet;

    #[view]
    fn getSetAddress_() -> TempContractAddress {
        toSet::get()
    }

    #[external]
    fn setSetAddress_(address: TempContractAddress) {
        toSet::set(address);
    }

    //from contracts.ecosystem.to_box import (getBoxAddress_, setBoxAddress_)
    use briq_protocol::ecosystem::to_box::toBox;
    #[view]
    fn getBoxAddress_() -> TempContractAddress {
        toBox::get()
    }

    #[external]
    fn setBoxAddress_(address: TempContractAddress) {
        toBox::set(address);
    }

    //

    #[view]
    fn name() -> felt252 {
        'briq'
    }

    #[view]
    fn symbol() -> felt252 {
        'briq'
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

    use traits::Into;
    use traits::TryInto;
    use option::OptionTrait;
    use briq_protocol::utils;

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
    use array::ArrayTrait;
    #[view]
    fn uri(id: u256) -> Array<felt252> {
        let mut out = ArrayTrait::<felt252>::new();
        out.append('briq');
        out
    }
}