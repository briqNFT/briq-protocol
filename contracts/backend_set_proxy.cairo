%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin, BitwiseBuiltin
from starkware.starknet.common.syscalls import get_caller_address
from starkware.starknet.common.syscalls import call_contract, delegate_l1_handler, delegate_call

from contracts.backend_proxy import (
    Proxy_implementation_address,

    _constructor,
    setImplementation,
    
    _onlyAdmin,
    _onlyAdminAnd,

    __default__,
)

####################
####################
####################
# Backend proxies don't delegate the calls, but instead call.
# This is because the backend proxy handles authorization,
# the actual backend contract only checks that its caller is the proxy.

@constructor
func constructor{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    } (owner: felt):
    _constructor(owner)
    return ()
end

####################
####################
####################
# Forwarded calls

####################
# No-Auth functions
# Note that these functions can be called directly, but for convenience they're also proxied.
@external
@raw_input
@raw_output
func balanceOf{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
    } (selector: felt, calldata_size: felt, calldata: felt*) -> (retdata_size: felt,retdata: felt*):
    let (address) = Proxy_implementation_address.read()
    let (retdata_size: felt, retdata: felt*) = call_contract(contract_address=address, function_selector=selector, calldata_size=calldata_size, calldata=calldata)
    return (retdata_size=retdata_size, retdata=retdata)
end

@external
@raw_input
@raw_output
func balanceDetailsOf{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
    } (selector: felt, calldata_size: felt, calldata: felt*) -> (retdata_size: felt,retdata: felt*):
    let (address) = Proxy_implementation_address.read()
    let (retdata_size: felt, retdata: felt*) = call_contract(contract_address=address, function_selector=selector, calldata_size=calldata_size, calldata=calldata)
    return (retdata_size=retdata_size, retdata=retdata)
end

@external
@raw_input
@raw_output
func tokenOfOwnerByIndex{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
    } (selector: felt, calldata_size: felt, calldata: felt*) -> (retdata_size: felt,retdata: felt*):
    let (address) = Proxy_implementation_address.read()
    let (retdata_size: felt, retdata: felt*) = call_contract(contract_address=address, function_selector=selector, calldata_size=calldata_size, calldata=calldata)
    return (retdata_size=retdata_size, retdata=retdata)
end

@external
@raw_input
@raw_output
func ownerOf{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
    } (selector: felt, calldata_size: felt, calldata: felt*) -> (retdata_size: felt,retdata: felt*):
    let (address) = Proxy_implementation_address.read()
    let (retdata_size: felt, retdata: felt*) = call_contract(contract_address=address, function_selector=selector, calldata_size=calldata_size, calldata=calldata)
    return (retdata_size=retdata_size, retdata=retdata)
end

@external
@raw_input
@raw_output
func tokenUri{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
    } (selector: felt, calldata_size: felt, calldata: felt*) -> (retdata_size: felt,retdata: felt*):
    let (address) = Proxy_implementation_address.read()
    let (retdata_size: felt, retdata: felt*) = call_contract(contract_address=address, function_selector=selector, calldata_size=calldata_size, calldata=calldata)
    return (retdata_size=retdata_size, retdata=retdata)
end

####################
# Authenticated functions

from contracts.types import (FTSpec)

@contract_interface
namespace ISetBackend:
    func ownerOf(token_id: felt) -> (owner: felt):
    end

    func assemble(owner: felt, token_id: felt, fts_len: felt, fts: FTSpec*, nfts_len: felt, nfts: felt*):
    end
    func disassemble(owner: felt, token_id: felt, fts_len: felt, fts: FTSpec*, nfts_len: felt, nfts: felt*):
    end
    func setTokenUri(token_id: felt, uri_len: felt, uri: felt*):
    end
    func transferOneNFT(sender: felt, recipient: felt, token_id: felt):
    end
end


@external
func assemble{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    } (owner: felt, token_id: felt, fts_len: felt, fts: FTSpec*, nfts_len: felt, nfts: felt*):
    alloc_locals    
    _onlyAdminAnd(owner)

    #local pedersen_ptr: HashBuiltin* = pedersen_ptr
    let (address) = Proxy_implementation_address.read()
    
    ISetBackend.assemble(address, owner, token_id, fts_len, fts, nfts_len, nfts)
    return ()
end

@external
func disassemble{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    } (owner: felt, token_id: felt, fts_len: felt, fts: FTSpec*, nfts_len: felt, nfts: felt*):
    alloc_locals
    _onlyAdminAnd(owner)
    
    #local pedersen_ptr: HashBuiltin* = pedersen_ptr
    let (address) = Proxy_implementation_address.read()
    
    ISetBackend.disassemble(address, owner, token_id, fts_len, fts, nfts_len, nfts)
    return ()
end

@external
func setTokenUri{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        bitwise_ptr: BitwiseBuiltin*,
        range_check_ptr
    } (token_id: felt, uri_len: felt, uri: felt*):
    alloc_locals
    let (address) = Proxy_implementation_address.read()
    let (owner) = ISetBackend.ownerOf(address, token_id)
    _onlyAdminAnd(owner)
    
    ISetBackend.setTokenUri(address, token_id, uri_len, uri)
    return ()
end

@external
func transferOneNFT{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    } (sender: felt, recipient: felt, token_id: felt):
    _onlyAdminAnd(sender)
    let (address) = Proxy_implementation_address.read()
    ISetBackend.transferOneNFT(address, sender, recipient, token_id)
    return ()
end
