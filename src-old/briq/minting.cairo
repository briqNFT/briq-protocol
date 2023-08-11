use traits::Into;
use traits::TryInto;
use option::OptionTrait;
use starknet::contract_address;

use briq_protocol::ecosystem::to_box::toBox;
use briq_protocol::library_erc1155::balance::Balance;
use briq_protocol::library_erc1155::transferability::Transferability;
use briq_protocol::briq::balance_enumerability::BalanceEnum::_setMaterialByOwner;
use briq_protocol::utilities::authorization::Auth::_onlyAdminAnd;

use briq_protocol::utils::GetCallerAddress;
use briq_protocol::utils;


fn _onlyAdminAndBoxContract() {
    _onlyAdminAnd(toBox::get().try_into().unwrap());
}

#[contract]
mod TotalSupply {
    struct Storage {
        // Delta with cairo 0 - this was "material -> supply", it is now "token ID -> supply"
        _total_supply: LegacyMap<felt252, felt252>,
    }
    
    //#[view]
    fn totalSupplyOfMaterial(material: felt252) -> felt252 { //(supply: felt252) {
        _total_supply::read(material)
    }

}

//@external
fn mintFT_(owner: felt252, material: felt252, qty: felt252) {
    _onlyAdminAndBoxContract();

    assert(owner != 0, 'Invalid owner');
    assert(material != 0, 'Invalid material');
    assert(qty != 0, 'Invalid quantity');

    // Update total supply.
    let res = TotalSupply::_total_supply::read(material);
    //with_attr error_message("Overflow in total supply") {
    assert(res < res + qty, 'Overflow total supply');
    TotalSupply::_total_supply::write(material, res + qty);

    // Update balance
    let balance = Balance::_increaseBalance(owner, material, qty);

    // Update enumerability
    _setMaterialByOwner(owner, material, 0);

    Transferability::TransferSingle(GetCallerAddress(), 0, owner, material.into(), qty.into());
}
