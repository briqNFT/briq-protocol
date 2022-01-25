%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin, BitwiseBuiltin
from starkware.starknet.common.syscalls import call_contract, delegate_l1_handler, delegate_call
from starkware.cairo.common.math import assert_nn_le, assert_lt, assert_le, assert_not_zero, assert_lt_felt, unsigned_div_rem
from starkware.cairo.common.math import split_felt
from starkware.cairo.common.uint256 import Uint256

from contracts.proxy.library import (
    Proxy_implementation_address
)

###############
###############
# This interface is compatible with OZ's ERC721 api.
# NB: this is always going to be slower than calling the backend directly.

from contracts.types import (FTSpec)

@contract_interface
namespace ISetBackend:
    func ownerOf(token_id: felt):
    end
    func tokenUri(token_id: felt) -> (uri_len: felt, uri: felt*):
    end
    func tokenOfOwnerByIndex(owner: felt, index: felt) -> (token_id: felt):
    end

    func setProxyAddress(address: felt):
    end
    func setBriqBackendAddress(address: felt):
    end
    func assemble(owner: felt, token_id_hint: felt, fts_len: felt, fts: FTSpec*, nfts_len: felt, nfts: felt*):
    end
    func disassemble(owner: felt, token_id: felt, fts_len: felt, fts: FTSpec*, nfts_len: felt, nfts: felt*):
    end
    func setTokenUri(token_id: felt, uri_len: felt, uri: felt*):
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
    assert_lt_felt(token_id.high, 2**122)
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
    assert_lt_felt(index.high, 2**122)
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
    assert_lt_felt(token_id.high, 2**122)
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
    assert_lt_felt(token_id.high, 2**122)
    tempvar tok = token_id.high * (2 ** 128) + token_id.low
    tempvar cd: felt*
    cd[0] = _from
    cd[1] = to
    cd[2] = tok
    
    let (address) = Proxy_implementation_address.read()
    let (retdata_size: felt, retdata: felt*) = delegate_call(contract_address=address, function_selector=ISetBackend.transferOneNFT, calldata_size=3, calldata=cd)
    return ()
end

func approve(approved: felt, token_id: Uint256):
    # TODO
    return ()
end

func setApprovalForAll(operator: felt, approved: felt):
    # TODO
    return ()
end

func getApproved(token_id: Uint256) -> (approved: felt):
    # TODO
    return (0)
end

func isApprovedForAll(owner: felt, operator: felt) -> (is_approved: felt):
    # TODO
    return (0)
end
