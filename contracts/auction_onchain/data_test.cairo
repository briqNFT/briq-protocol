%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin

from contracts.auction_onchain.data_link import AuctionData

@view
func get_auction_data{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    token_id: felt,
) -> (
    data: AuctionData,
){
    let data = AuctionData(
        minimum_bid=1210,
        bid_growth_factor=10,
        auction_start_date=100,
        auction_duration=100,
    );
    return (data,);
}

