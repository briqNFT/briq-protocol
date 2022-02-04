%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin, BitwiseBuiltin
from starkware.starknet.common.syscalls import call_contract, delegate_l1_handler, delegate_call
from starkware.cairo.common.math import assert_nn_le, assert_lt, assert_le, assert_not_zero, assert_lt_felt, unsigned_div_rem
from starkware.cairo.common.math import split_felt
from starkware.cairo.common.uint256 import Uint256

from contracts.backend_proxy import (
    Proxy_implementation_address,

    _constructor,
    setImplementation,
    setAdmin,
)

####################
####################
####################
# Frontend proxies delegate the calls to backend proxies.
# They don't check authorizations because that's done there.

@constructor
func constructor{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    } (owner: felt):
    _constructor(owner)
    return ()
end

###############
###############
# This interface is compatible with OZ's ERC721 api.
# NB: this is always going to be slower than calling the backend directly.

from contracts.types import (FTSpec)

# Actually the interface of the proxy.
@contract_interface
namespace ISetBackend:
    func ownerOf(token_id: felt):
    end
    func tokenUri(token_id: felt) -> (uri_len: felt, uri: felt*):
    end
    func tokenOfOwnerByIndex(owner: felt, index: felt) -> (token_id: felt):
    end

    func approve(approved_address: felt, token_id: felt):
    end
    func getApproved(token_id: felt) -> (approved: felt):
    end
    func setApprovalForAll(approved_address: felt, allowed: felt):
    end
    func isApprovedForAll(owner: felt, operator: felt) -> (is_approved: felt):
    end

    func transferOneNFT(sender: felt, recipient: felt, token_id: felt):
    end
end

## Metadata
@view
func name() -> (name: felt):
    return (0x62726971)
end

@view
func symbol() -> (symbol: felt):
    return (0x62726971)
end

# Technically not OZ's implementation.
@view
@raw_output
func tokenURI{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    } (token_id: Uint256) -> (retdata_size : felt, retdata : felt*):
    assert_lt_felt(token_id.high, 2**123)
    tempvar tok = token_id.high * (2 ** 128) + token_id.low
    tempvar cd: felt*
    cd[0] = tok
    
    let (address) = Proxy_implementation_address.read()
    let (retdata_size: felt, retdata: felt*) = delegate_call(contract_address=address, function_selector=ISetBackend.tokenUri, calldata_size=1, calldata=cd)
    return (retdata_size, retdata)
end

## Subset of enumerability
@view
func tokenOfOwnerByIndex{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    } (owner: felt, index: Uint256) -> (tokenId: Uint256):
    assert_lt_felt(index.high, 2**123)
    tempvar tok = index.high * (2 ** 128) + index.low
    tempvar cd: felt*
    cd[1] = owner
    cd[0] = tok
    
    let (address) = Proxy_implementation_address.read()
    let (retdata_size: felt, retdata: felt*) = delegate_call(contract_address=address, function_selector=ISetBackend.tokenOfOwnerByIndex, calldata_size=2, calldata=cd)
    
    let (high, low) = split_felt(retdata[0])
    tempvar res: Uint256
    res.high = high
    res.low = low
    return (res)
end

## Regular ERC721

@view
@raw_input
func balanceOf{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    } (selector: felt, calldata_size: felt, calldata: felt*) -> (balance: Uint256):
    let (address) = Proxy_implementation_address.read()
    let (retdata_size: felt, retdata: felt*) = delegate_call(contract_address=address, function_selector=selector, calldata_size=calldata_size, calldata=calldata)
    
    let (high, low) = split_felt(retdata[0])
    tempvar res: Uint256
    res.high = high
    res.low = low
    return (res)
end

@view
@raw_output
func ownerOf{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    } (token_id: Uint256) -> (retdata_size : felt, retdata : felt*):
    assert_lt_felt(token_id.high, 2**123)
    tempvar tok = token_id.high * (2 ** 128) + token_id.low
    tempvar cd: felt*
    cd[0] = tok
    
    let (address) = Proxy_implementation_address.read()
    let (retdata_size: felt, retdata: felt*) = delegate_call(contract_address=address, function_selector=ISetBackend.ownerOf, calldata_size=1, calldata=cd)
    return (retdata_size, retdata)
end

@external
func safeTransferFrom{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    } (
        _from: felt, 
        to: felt, 
        token_id: Uint256, 
        data_len: felt,
        data: felt*
    ):
    # TODO validate
    transferFrom(_from, to, token_id)
    return ()
end

@external
func transferFrom{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    } (_from: felt, to: felt, token_id: Uint256):
    assert_lt_felt(token_id.high, 2**123)
    tempvar tok = token_id.high * (2 ** 128) + token_id.low
    tempvar cd: felt*
    cd[0] = _from
    cd[1] = to
    cd[2] = tok
    
    let (address) = Proxy_implementation_address.read()
    let (retdata_size: felt, retdata: felt*) = delegate_call(contract_address=address, function_selector=ISetBackend.transferOneNFT, calldata_size=3, calldata=cd)
    return ()
end

@external
func approve{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    } (approved: felt, token_id: Uint256):
    assert_lt_felt(token_id.high, 2**123)
    tempvar tok = token_id.high * (2 ** 128) + token_id.low
    tempvar cd: felt*
    cd[0] = approved
    cd[1] = tok
    let (address) = Proxy_implementation_address.read()
    let (retdata_size: felt, retdata: felt*) = delegate_call(contract_address=address, function_selector=ISetBackend.approve, calldata_size=2, calldata=cd)
    return ()
end

@external
@raw_input
@raw_output
func setApprovalForAll{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    } (selector: felt, calldata_size: felt, calldata: felt*) -> (retdata_size: felt,retdata: felt*):
    let (address) = Proxy_implementation_address.read()
    let (retdata_size: felt, retdata: felt*) = call_contract(contract_address=address, function_selector=selector, calldata_size=calldata_size, calldata=calldata)
    return (retdata_size=retdata_size, retdata=retdata)
end

@external
@raw_output
func getApproved{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    } (token_id: Uint256) -> (retdata_size: felt,retdata: felt*):
    assert_lt_felt(token_id.high, 2**123)
    tempvar tok = token_id.high * (2 ** 128) + token_id.low
    tempvar cd: felt*
    cd[0] = tok
    let (address) = Proxy_implementation_address.read()
    let (retdata_size: felt, retdata: felt*) = delegate_call(contract_address=address, function_selector=ISetBackend.getApproved, calldata_size=1, calldata=cd)
    return (retdata_size=retdata_size, retdata=retdata)
end

@external
@raw_input
@raw_output
func isApprovedForAll{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    } (selector: felt, calldata_size: felt, calldata: felt*) -> (retdata_size: felt,retdata: felt*):
    let (address) = Proxy_implementation_address.read()
    let (retdata_size: felt, retdata: felt*) = call_contract(contract_address=address, function_selector=selector, calldata_size=calldata_size, calldata=calldata)
    return (retdata_size=retdata_size, retdata=retdata)
end
