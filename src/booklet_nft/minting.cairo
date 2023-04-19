use traits::Into;
use traits::TryInto;
use option::OptionTrait;

use starknet::contract_address;

use briq_protocol::library_erc1155;
use briq_protocol::library_erc1155::transferability::Transferability;
use briq_protocol::booklet_nft::token_uri;
use briq_protocol::utils::GetCallerAddress;
use briq_protocol::utils;

use briq_protocol::ecosystem::genesis_collection::DUCKS_COLLECTION;
use briq_protocol::ecosystem::to_box::toBox;
use briq_protocol::utilities::authorization::Auth::_onlyAdminAnd;

use briq_protocol::booklet_nft::token_uri::toShapeContract;

//@external
fn mint_(owner: felt252, token_id: felt252, shape_contract: felt252) {
    library_erc1155::balance::Balance::_increaseBalance(owner, token_id, 1);

    toShapeContract::_shape_contract::write(token_id, shape_contract);

    let caller = GetCallerAddress();
    // Can only be minted by the box contract or an admin of the contract.
    if (caller == 0x02ef9325a17d3ef302369fd049474bc30bfeb60f59cca149daa0a0b7bcc278f8) {
        // Allow OutSmth to mint ducks.
        let tid = (token_id - DUCKS_COLLECTION) / 0x1000000000000000000000000000000000000000000000000;
        // Check this is below an arbitrary low number to make sure the range is correct
        assert(tid < 10000, 'Invalid token id');

        Transferability::TransferSingle(caller, 0, owner, token_id.into(), 1.into());
        return ();
    } else {
        _onlyAdminAnd(toBox::get().try_into().unwrap());

        Transferability::TransferSingle(caller, 0, owner, token_id.into(), 1.into());
        return ();
    }
}
