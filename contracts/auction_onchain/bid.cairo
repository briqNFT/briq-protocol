%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin

from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.math import (
    assert_le_felt,
    split_int,
    unsigned_div_rem
)

from starkware.starknet.common.syscalls import (
    get_block_number,
    get_caller_address,
    get_contract_address,
    get_block_timestamp,
)

from contracts.vendor.openzeppelin.token.erc20.IERC20 import IERC20

from contracts.utilities.Uint256_felt_conv import _felt_to_uint

from contracts.auction_onchain.payment_token import getPaymentAddress_

struct Bid {
    account: felt,
    amount: felt,
}

struct AuctionData {
    token_id: felt, // ?
    minimum_bid: felt,
    bid_growth_factor: felt, // Or maybe absolute value?
    auction_start_date: felt,
    auction_duration: felt,
}

const MAXIMUM_CONCURRENT_BIDS = 5;

@storage_var
func current_best_bid(token_id: felt) -> (bid: Bid) {
}

@storage_var
func account_bids(account: felt) -> (bids: felt) {
}

@view
func get_auction_data{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    token_id: felt,
) -> (
    data: AuctionData,
){
    let data = AuctionData(
        token_id=token_id,
        minimum_bid=1210,
        bid_growth_factor=10,
        auction_start_date=100,
        auction_duration=100,
    );
    return (data,);
}

@external
func make_bids{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    token_ids_len: felt,
    token_ids: felt*,
    amounts_len: felt,
    amounts: felt*,
) {
    alloc_locals;
    let (bidder) = get_caller_address();

    assert token_ids_len = amounts_len;
    assert token_ids_len = MAXIMUM_CONCURRENT_BIDS;

    let (bids) = alloc();
    let (abids) = account_bids.read(bidder);
    split_int(abids, 5, 2**8, 2**8, bids);

    let (out_bids) = alloc();
    _make_bids(bidder, MAXIMUM_CONCURRENT_BIDS, token_ids, amounts, bids, out_bids, 1);

    // update bids.
    account_bids.write(bidder,
        out_bids[0] +
        out_bids[1] * 2**8 +
        out_bids[2] * 2**16 +
        out_bids[3] * 2**24 +
        out_bids[4] * 2**32
    );

    return ();
}


func _make_bids{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    bidder: felt,
    i: felt,
    token_ids: felt*,
    amounts: felt*,
    bids: felt*,
    out_bids: felt*,
    allow_new: felt,
) {
    alloc_locals;
    if (i == 0) {
        return ();
    }

    _make_bid(bidder, token_ids[0], amounts[0], bids[0], out_bids, allow_new);

    if (bids[0] == 0 and token_ids[0] == 0) {
        return _make_bids(bidder, i - 1, token_ids + 1, amounts + 1, bids + 1, out_bids + 1, 0);
    }
    return _make_bids(bidder, i - 1, token_ids + 1, amounts + 1, bids + 1, out_bids + 1, allow_new);
}

func _make_bid{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    bidder: felt,
    token_id: felt,
    amount: felt,
    bid: felt,
    out_bid: felt*,
    allow_new: felt,
) {
    alloc_locals;

    // First, check if this bid is a bid or a placeholder.
    if (token_id == 0) {
        assert out_bid[0] = bid;
        return ();
    }

    // If it's a bid, make sure it's the correct one (so that we limit the concurrent bids).
    // This means we're either overwriting or writing a new bid ( == 0 )
    if (bid != 0) {
        assert token_id = bid;
    } else {
        assert allow_new = 1;
    }
    assert out_bid[0] = token_id;

    // For each bid.
    // Validate bid:
    // - Must be x% higher than last bid and min bid.
    // - Auction must not have completed (there will be a final block to send auctions)
    // - Auction must have started (won't work before some timestamp)
    // Then the funds must transfer to the contract.
    // Then we reimburse the current bid.
    // Then we update the current bid storage variable.

    let (auction_data) = get_auction_data(token_id);
    let (current_bid) = current_best_bid.read(token_id);
    let t = current_bid.amount;

    // Must clear min bid
    assert_le_felt(auction_data.minimum_bid, amount);

    // Must be x% higher than last bid.
    // (this returns 0 for 0, which is fine).
    // (This assumes the minimum bid is at least 1000 wei)
    let (hike_permil, _) = unsigned_div_rem(current_bid.amount, 1000);
    assert_le_felt(current_bid.amount + hike_permil * auction_data.bid_growth_factor, amount);

    // Auction must not have completed (there will be a final block to send auctions)
    let (block_timestamp) = get_block_timestamp();
    assert_le_felt(block_timestamp, auction_data.auction_start_date + auction_data.auction_duration);

    // Auction must have started (won't work before some timestamp)
    let (block_timestamp) = get_block_timestamp();
    assert_le_felt(auction_data.auction_start_date, block_timestamp);

    // Done with verifications, now transfer funds.
    with_attr error_message("Failed to transfer ETH funds") {
        let (contract_address) = get_contract_address();
        let (price_as_uint) = _felt_to_uint(amount);
        let (erc20_address) = getPaymentAddress_();
        IERC20.transferFrom(erc20_address, bidder, contract_address, price_as_uint);
    }

    // Now pay back current bidder
    _pay_back_funds(current_bid);

    // Then store new current bid.
    current_best_bid.write(token_id, Bid(account=bidder, amount=amount));
    return ();
}

func _pay_back_funds{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    current_bid: Bid
) {
    alloc_locals;
    if (current_bid.amount != 0) {
        with_attr error_message("Failed to pay back current bidder") {
            let (contract_address) = get_contract_address();
            let (price_as_uint) = _felt_to_uint(current_bid.amount);
            let (erc20_address) = getPaymentAddress_();
            IERC20.transfer(erc20_address, current_bid.account, price_as_uint);
        }
        return ();
    } else {
        return ();
    }
}

@external
func settle_auction{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
) {
    return ();
}
