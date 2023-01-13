%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin

from contracts.utilities.authorization import _onlyAdmin

struct AuctionData {
    minimum_bid: felt,
    bid_growth_factor: felt, // Or maybe absolute value?
    auction_start_date: felt,
    auction_duration: felt,
}

@contract_interface
namespace IDataContract {
    func get_auction_data(
        token_id: felt
    ) -> (
       data: AuctionData,
    ){
    }
}

@storage_var
func _data_hash() -> (hash: felt) {
}

@view
func getDataHash_{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (
    hash: felt
) {
    let (value) = _data_hash.read();
    return (value,);
}

@external
func setDataHash_{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    hash: felt
) {
    _onlyAdmin();
    _data_hash.write(hash);
    return ();
}
