%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin

from contracts.auction_onchain.data_link import AuctionData

from starkware.cairo.common.registers import get_label_location

auction_data_start:
dw 1210; // minimum bid (wei)
dw 10; // growth factor (in per mil)
dw 1673606220; // start date
dw 864000; // duration
dw 1000;
dw 10;
dw 1675606203;
dw 864000; // duration
auction_data_end:

@view
func get_auction_data{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    token_id: felt,
) -> (
    data: AuctionData,
){
    let (start) = get_label_location(auction_data_start);
    let data = cast(start + AuctionData.SIZE * token_id, AuctionData*)[0];
    return (data,);
}

