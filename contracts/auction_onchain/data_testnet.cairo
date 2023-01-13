%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin

from starkware.cairo.common.math import (
    assert_le_felt,
    assert_not_zero,
)

from starkware.cairo.common.registers import get_label_location

from contracts.auction_onchain.data_link import AuctionData

auction_data_start:
dw 0x210343a6ce65eaf6818b9fc8e744930e363d9a263918e94000000000000000; // token ID
dw 1210; // minimum bid (wei)
dw 10; // growth factor (in per mil)
dw 1673606220; // start date
dw 864000; // duration

dw 0x7d180b4de0656c2d58237be7a77cf1403be2226f42e63a7b800000000000000; // token ID
dw 1000;
dw 10;
dw 1675606203;
dw 864000; // duration
auction_data_end:

@view
func get_auction_data{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    auction_id: felt,
) -> (
    data: AuctionData,
){
    let (start) = get_label_location(auction_data_start);
    let (end) = get_label_location(auction_data_end);
    
    assert_not_zero(auction_id);
    assert_le_felt(auction_id, (end - start) / AuctionData.SIZE);

    let data = cast(start + AuctionData.SIZE * (auction_id - 1), AuctionData*)[0];
    return (data,);
}

