%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin

from contracts.auction_onchain.data_link import AuctionData

from contracts.auction_onchain.allowlist_test import _onlyAllowed

@view
func get_auction_data{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    auction_id: felt,
) -> (
    data: AuctionData,
){
    // For convenience, the whitelist check is done here.
    // This makes it easier to change on a per-network basis, and it's called as part of making bids anyways.
    _onlyAllowed();

    // Special case for testing
    if (auction_id == 20) {
        let data = AuctionData(
            token_id=0,
            minimum_bid=0,
            bid_growth_factor=0,
            auction_start_date=0,
            auction_duration=0,
        );
        return (data,);
    }

    let data = AuctionData(
        token_id=auction_id,
        minimum_bid=1210,
        bid_growth_factor=10,
        auction_start_date=100,
        auction_duration=100,
    );
    return (data,);
}

