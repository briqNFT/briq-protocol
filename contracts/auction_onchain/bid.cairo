%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin

from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.math import (
    assert_not_zero,
    assert_le_felt,
    assert_lt_felt,
    split_int,
    unsigned_div_rem
)

from starkware.starknet.common.syscalls import (
    get_block_number,
    get_caller_address,
    get_contract_address,
    get_block_timestamp,
)

from contracts.auction_onchain.payment_token import getPaymentAddress_
from contracts.auction_onchain.data_link import AuctionData, IDataContract, getDataHash_

from contracts.ecosystem.to_set import getSetAddress_

from contracts.vendor.openzeppelin.token.erc20.IERC20 import IERC20

from contracts.utilities.Uint256_felt_conv import _felt_to_uint
from contracts.utilities.authorization import _onlyAdmin

struct BidData {
    account: felt,
    amount: felt,
}

const MAXIMUM_CONCURRENT_BIDS = 5;

@event
func Bid(bidder: felt, bid_amount: felt, auction_id: felt) {
}

@event
func AuctionComplete(auction_id: felt, winner: felt) {
}

@storage_var
func current_best_bid(auction_id: felt) -> (bid: BidData) {
}

@storage_var
func account_bids(account: felt) -> (bids: felt) {
}


@view
func get_auction_data{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    auction_id: felt,
) -> (
    data: AuctionData,
){
    assert_not_zero(auction_id);

    let (hash) = getDataHash_();
    let (data) = IDataContract.library_call_get_auction_data(hash, auction_id);
    return (data,);
}

@external
func make_bids{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    auction_ids_len: felt,
    auction_ids: felt*,
    amounts_len: felt,
    amounts: felt*,
) {
    alloc_locals;
    let (bidder) = get_caller_address();

    assert auction_ids_len = amounts_len;
    assert auction_ids_len = MAXIMUM_CONCURRENT_BIDS;

    let (bids) = alloc();
    let (abids) = account_bids.read(bidder);
    split_int(abids, 5, 2**8, 2**8, bids);

    let (out_bids) = alloc();
    _make_bids(bidder, MAXIMUM_CONCURRENT_BIDS, auction_ids, amounts, bids, out_bids, 1);

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
    auction_ids: felt*,
    amounts: felt*,
    bids: felt*,
    out_bids: felt*,
    allow_new: felt,
) {
    alloc_locals;
    if (i == 0) {
        return ();
    }

    _make_bid(bidder, auction_ids[0], amounts[0], bids[0], out_bids, allow_new);

    if (bids[0] == 0 and auction_ids[0] == 0) {
        return _make_bids(bidder, i - 1, auction_ids + 1, amounts + 1, bids + 1, out_bids + 1, 0);
    }
    return _make_bids(bidder, i - 1, auction_ids + 1, amounts + 1, bids + 1, out_bids + 1, allow_new);
}

func _make_bid{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    bidder: felt,
    auction_id: felt,
    amount: felt,
    bid: felt,
    out_bid: felt*,
    allow_new: felt,
) {
    alloc_locals;

    // First, check if this bid is a bid or a placeholder.
    if (auction_id == 0) {
        assert out_bid[0] = bid;
        return ();
    }

    // If it's a bid, make sure it's the correct one (so that we limit the concurrent bids).
    // This means we're either overwriting or writing a new bid ( == 0 )
    if (bid != 0) {
        assert auction_id = bid;
    } else {
        assert allow_new = 1;
    }
    assert out_bid[0] = auction_id;

    // For each bid.
    // Validate bid:
    // - Must be x% higher than last bid and min bid.
    // - Auction must not have completed (there will be a final block to send auctions)
    // - Auction must have started (won't work before some timestamp)
    // Then the funds must transfer to the contract.
    // Then we reimburse the current bid.
    // Then we update the current bid storage variable.

    let (auction_data) = get_auction_data(auction_id);
    let (current_bid) = current_best_bid.read(auction_id);

    assert_not_zero(auction_data.token_id);

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
    current_best_bid.write(auction_id, BidData(account=bidder, amount=amount));

    // Then emit event
    Bid.emit(bidder, amount, auction_id);

    return ();
}

func _pay_back_funds{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    current_bid: BidData
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
func settle_auctions{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    auction_ids_len: felt,
    auction_ids: felt*
) {
    _onlyAdmin();

    if (auction_ids_len == 0) {
        return ();
    }

    assert_not_zero(auction_ids[0]);

    // Make sure the auction is over.
    let (auction_data) = get_auction_data(auction_ids[0]);
    let (block_timestamp) = get_block_timestamp();
    assert_lt_felt(auction_data.auction_start_date + auction_data.auction_duration, block_timestamp);

    // Perform the auction.
    let (bid) = current_best_bid.read(auction_ids[0]);
    _settle_token(auction_data.token_id, bid.account);

    return settle_auctions(auction_ids_len - 1, auction_ids + 1);
}

@contract_interface
namespace ISetContract {
    func transferFrom_(
        sender: felt, recipient: felt, token_id: felt
    ) {
    }
}

func _settle_token{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    token_id: felt,
    owner: felt,
) {
    // Do nothing if there was no bid.
    if (owner == 0) {
        return ();
    }

    let (set_address) = getSetAddress_();
    let (contract_address) = get_contract_address();
    ISetContract.transferFrom_(set_address, contract_address, owner, token_id);
    return ();
}


@external
func transfer_funds{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    receiver: felt, amount: felt
) {
    _onlyAdmin();
    assert_not_zero(receiver);

    let (amnt) = _felt_to_uint(amount);

    let (erc20_address) = getPaymentAddress_();
    with_attr error_message("Failed to transfer ETH funds") {
        IERC20.transfer(erc20_address, receiver, amnt);
    }
    return ();
}
