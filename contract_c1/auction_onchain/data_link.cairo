%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin

from contracts.utilities.authorization import _onlyAdmin

struct AuctionData {
    token_id: felt, // The actual token ID being bid on
    minimum_bid: felt, // Minimum bid in WEI
    bid_growth_factor: felt, // per mil minimum increase over current bid
    auction_start_date: felt, // timestamp in seconds
    auction_duration: felt, // in seconds
}

@contract_interface
namespace IDataContract {
    func get_auction_data(
        auction_id: felt
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
