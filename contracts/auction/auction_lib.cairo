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
from starkware.cairo.common.uint256 import (
    Uint256,
    uint256_le,
    uint256_mul,
    uint256_sub,
)
from starkware.starknet.common.syscalls import (
    get_block_number,
    get_caller_address,
    get_contract_address
)

from starkware.cairo.common.registers import get_label_location

from contracts.OZ.token.erc20.interfaces.IERC20 import IERC20
from contracts.OZ.token.erc721.interfaces.IERC721 import IERC721
from starkware.cairo.common.bool import FALSE, TRUE

from contracts.utilities.Uint256_felt_conv import _felt_to_uint

from contracts.utilities.authorization import _onlyAdmin


from contracts.auction.data import (
    auction_data_start,
    auction_data_end,
    box_address
)

@event
func Bid(payer: felt, payer_erc20_contract: felt, box_token_id: felt, bid_amount: felt):
end

struct BidData:
    member payer: felt
    member payer_erc20_contract: felt
    member box_token_id: felt
    member bid_amount: felt
end

struct AuctionData:
    member box_token_id: felt # Token ID of the box
    member total_supply: felt # Total supply of items
    member auction_start: felt # timestamp of the auction start, in seconds
    member auction_duration: felt # duration of the auction in seconds
end

@external
func make_bid{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(
        bid: BidData
    ):
    alloc_locals

    let (caller) = get_caller_address()
    assert caller = bid.payer

    # Sanity checks
    assert_not_zero(bid.payer)
    assert_not_zero(bid.payer_erc20_contract)
    assert_not_zero(bid.box_token_id)

    with_attr error_message("Bid must be greater than 0"):
        assert_not_zero(bid.bid_amount)
    end

    # TODO: assert box exists and is up for grabs.
    # TODO: we are in the correct time range for auction

    Bid.emit(bid.payer, bid.payer_erc20_contract, bid.box_token_id, bid.bid_amount)

    let (bid_as_uint) = _felt_to_uint(bid.bid_amount)
    let (contract_address) = get_contract_address()
    let (allowance) = IERC20.allowance(bid.payer_erc20_contract, bid.payer, contract_address)
    let (balance) = IERC20.balanceOf(bid.payer_erc20_contract, bid.payer)
    
    with_attr error_message("Bid greater than allowance"):
        let (ok) = uint256_le(bid_as_uint, allowance)
        assert ok = TRUE
    end

    let (bid_as_uint) = _felt_to_uint(bid.bid_amount)
    with_attr error_message("Bid greater than balance"):
        let (ok) = uint256_le(bid_as_uint, balance)
        assert ok = TRUE
    end

    return ()
end


@external
func close_auction{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(
        bids_len: felt,
        bids: BidData*
    ):
    _onlyAdmin()

    assert_not_zero(bids_len)

    try_bid(bids_len, bids, bids[0])

    return ()
end

@contract_interface
namespace IBoxContract:
    func safeTransferFrom_(sender: felt, recipient: felt, token_id: felt, value: felt, data_len : felt, data : felt*):
    end
end

func try_bid{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(
        bids_len: felt,
        bids: BidData*,
        last_bid: BidData,
    ):
    alloc_locals
    if (bids_len) == 0:
        with_attr error_message("All bids exhausted"):
            assert 0 = 1
        end
        return ()
    end
    let bid = bids[0]
    with_attr error_message("Bids incorrectly ordered"):
        assert_le_felt(bid.bid_amount, last_bid.bid_amount)
    end

    let (contract_address) = get_contract_address()
    let (bid_as_uint) = _felt_to_uint(bid.bid_amount)
    # Note -> This actually must succeed otherwise the whole TX reverts, which is kind of annoying.
    let (success) = IERC20.transferFrom(bid.payer_erc20_contract, bid.payer, contract_address, bid_as_uint)
    if success == FALSE:
        return try_bid(bids_len - 1, bids + BidData.SIZE, bids[0])
    end
    IBoxContract.safeTransferFrom_(box_address, contract_address, bid.payer, bid.box_token_id, 1, 0, cast(0, felt*))
    return ()
end


@view
func get_auction_data{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }() -> (data_len: felt, data: AuctionData*):
    alloc_locals

    let (auction_data_start_label) = get_label_location(auction_data_start)
    let (auction_data_end_label) = get_label_location(auction_data_end)

    let nb = (auction_data_end_label - auction_data_start_label) / AuctionData.SIZE

    let res: AuctionData* = alloc()
    let (res_end) = _get_auction_data(nb, res)
    let nb = (res_end - res) / AuctionData.SIZE
    return (nb, res)
end

func _get_auction_data{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(n: felt, data: AuctionData*) -> (data_end: AuctionData*):
    if n == 0:
        return(data)
    end
    let (auction_data_start_label) = get_label_location(auction_data_start)
    let auction_data = cast(auction_data_start_label + (n-1) * AuctionData.SIZE, AuctionData*)[0]
    assert data[0] = auction_data
    return _get_auction_data(n-1, data + AuctionData.SIZE)
end