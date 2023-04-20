//###########
//###########
//###########
// # Authorization patterns
use traits::Into;
use traits::TryInto;
use option::OptionTrait;
use starknet::contract_address;

use briq_protocol::utilities::authorization::Auth::_only;

use briq_protocol::ecosystem::to_set::toSet;
use briq_protocol::utils::GetCallerAddress;

use briq_protocol::library_erc1155::transferability::Transferability;
use briq_protocol::briq::balance_enumerability::BalanceEnum;

fn _onlySetAnd(address: felt252) {
    if GetCallerAddress() == toSet::get() {
        return ();
    }
    _only(address.try_into().unwrap());
    return ();
}

//###########
//###########
//###########
// Admin functions

//@external
fn transferFT_(sender: felt252, recipient: felt252, material: felt252, qty: felt252) {
    _onlySetAnd(sender);

    Transferability::_transfer(sender, recipient, material, qty);

    // Needs to come after transfer for balances to be accurate.
    BalanceEnum::_maybeUnsetMaterialByOwner(sender, material);
    BalanceEnum::_setMaterialByOwner(recipient, material, 0);
}
