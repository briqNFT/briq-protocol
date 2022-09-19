%lang starknet

from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.math import (
    assert_le,
    assert_le_felt,
    assert_not_equal,
    assert_not_zero,
    split_felt,
)
from starkware.cairo.common.math_cmp import is_not_zero
from starkware.cairo.common.uint256 import Uint256, uint256_le, uint256_mul, uint256_sub
from starkware.starknet.common.syscalls import (
    get_block_number,
    get_caller_address,
    get_contract_address,
)

from starkware.cairo.common.registers import get_label_location

from contracts.OZ.token.erc20.interfaces.IERC20 import IERC20
from contracts.OZ.token.erc721.interfaces.IERC721 import IERC721
from starkware.cairo.common.bool import FALSE, TRUE

from contracts.utilities.Uint256_felt_conv import _felt_to_uint

from contracts.utilities.authorization import _onlyAdmin

from contracts.auction.data import auction_data_start, auction_data_end, box_address, erc20_address

struct AuctionData {
    box_token_id: felt,  // Token ID of the box that is being bought.
    total_supply: felt,  // Total supply of items. If 1, the auction is an English auction. Otherwise, Dutch.
    auction_start: felt,  // Timestamp of the auction start, in seconds.
    auction_duration: felt,  // Duration of the auction in seconds.
    initial_price: felt,  // Initial price, will either increase or decrease depending on auction type.
}

@event
func Bid(bidder: felt, box_token_id: felt, bid_amount: felt) {
}

struct BidData {
    bidder: felt,
    auction_index: felt,  // Hint to the contract to know where to find relevant data.
    box_token_id: felt,  // Box being bid on (must match)
    bid_amount: felt,
}

@external
func make_bid{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(bid: BidData) {
    alloc_locals;

    let (caller) = get_caller_address();
    assert caller = bid.bidder;

    // Sanity checks
    assert_not_zero(bid.bidder);
    assert_not_zero(bid.box_token_id);

    with_attr error_message("Bid must be greater than 0") {
        assert_not_zero(bid.bid_amount);
    }

    // TODO: assert box exists and is up for grabs.
    // TODO: we are in the correct time range for auction
    let (auction_data_start_label) = get_label_location(auction_data_start);
    let data = cast(auction_data_start_label + AuctionData.SIZE * bid.auction_index, AuctionData*)[0];

    with_attr error_message("box_token_id does not match auction_index") {
        assert data.box_token_id = bid.box_token_id;
    }

    let (bid_as_uint) = _felt_to_uint(bid.bid_amount);
    let (contract_address) = get_contract_address();
    let (allowance) = IERC20.allowance(erc20_address, bid.bidder, contract_address);
    let (balance) = IERC20.balanceOf(erc20_address, bid.bidder);

    with_attr error_message("Bid greater than allowance") {
        let (ok) = uint256_le(bid_as_uint, allowance);
        assert ok = TRUE;
    }

    let (bid_as_uint) = _felt_to_uint(bid.bid_amount);
    with_attr error_message("Bid greater than balance") {
        let (ok) = uint256_le(bid_as_uint, balance);
        assert ok = TRUE;
    }

    if (data.total_supply != 1) {
        let (bid_as_uint) = _felt_to_uint(bid.bid_amount);
        return _make_direct_bid(bid, data);
    }

    Bid.emit(bid.bidder, bid.box_token_id, bid.bid_amount);

    return ();
}

func _make_direct_bid{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    bid: BidData, data: AuctionData
) {
    // TODO: compute the price of the box.
    tempvar price = Uint256(50, 0);
    let (contract_address) = get_contract_address();
    IERC20.transferFrom(erc20_address, bid.bidder, contract_address, price);
    IBoxContract.safeTransferFrom_(
        box_address, contract_address, bid.bidder, bid.box_token_id, 1, 0, cast(0, felt*)
    );

    return ();
}

@external
func close_auction{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    bids_len: felt, bids: BidData*
) {
    _onlyAdmin();

    assert_not_zero(bids_len);

    try_bid(bids_len, bids, bids[0]);

    return ();
}

@contract_interface
namespace IBoxContract {
    func safeTransferFrom_(
        sender: felt, recipient: felt, token_id: felt, value: felt, data_len: felt, data: felt*
    ) {
    }
}

func try_bid{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    bids_len: felt, bids: BidData*, last_bid: BidData
) {
    alloc_locals;
    if ((bids_len) == 0) {
        with_attr error_message("All bids exhausted") {
            assert 0 = 1;
        }
        return ();
    }
    let bid = bids[0];
    with_attr error_message("Bids incorrectly ordered") {
        assert_le_felt(bid.bid_amount, last_bid.bid_amount);
    }

    let (contract_address) = get_contract_address();
    let (bid_as_uint) = _felt_to_uint(bid.bid_amount);
    // Note -> This actually must succeed otherwise the whole TX reverts, which is kind of annoying.
    let (success) = IERC20.transferFrom(erc20_address, bid.bidder, contract_address, bid_as_uint);
    if (success == FALSE) {
        return try_bid(bids_len - 1, bids + BidData.SIZE, bids[0]);
    }
    IBoxContract.safeTransferFrom_(
        box_address, contract_address, bid.bidder, bid.box_token_id, 1, 0, cast(0, felt*)
    );
    return ();
}

@view
func get_auction_data{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (
    data_len: felt, data: AuctionData*
) {
    alloc_locals;

    let (auction_data_start_label) = get_label_location(auction_data_start);
    let (auction_data_end_label) = get_label_location(auction_data_end);

    let nb = (auction_data_end_label - auction_data_start_label) / AuctionData.SIZE;

    let res: AuctionData* = alloc();
    let (res_end) = _get_auction_data(nb, res);
    let nb = (res_end - res) / AuctionData.SIZE;
    return (nb, res);
}

// Warning: n skips 0
func _get_auction_data{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    n: felt, data: AuctionData*
) -> (data_end: AuctionData*) {
    if (n == 0) {
        return (data,);
    }
    let (auction_data_start_label) = get_label_location(auction_data_start);
    let auction_data = cast(auction_data_start_label + (n - 1) * AuctionData.SIZE, AuctionData*)[0];
    assert data[0] = auction_data;
    return _get_auction_data(n - 1, data + AuctionData.SIZE);
}
