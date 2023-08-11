use traits::Into;

use briq_protocol::utilities::authorization::Auth::_onlyAdmin;
use briq_protocol::library_erc1155;

use briq_protocol::utils;
use briq_protocol::utils::GetCallerAddress;

//@external
fn mint_(owner: felt252, token_id: felt252, number: felt252) {
    _onlyAdmin();

    library_erc1155::balance::Balance::_increaseBalance(owner, token_id, number);

    library_erc1155::transferability::Transferability::TransferSingle(GetCallerAddress(), 0, owner, token_id.into(), number.into());

    // Make sure we have data for that token ID
    //let (_shape_data_start) = get_label_location(shape_data_start);
    //let (_shape_data_end) = get_label_location(shape_data_end);
    //assert_lt_felt(0, token_id);
    //assert_le_felt(token_id, _shape_data_end - _shape_data_start);
    assert(false, 'TODO');

    return ();
}
