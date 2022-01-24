%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin, SignatureBuiltin, BitwiseBuiltin
from starkware.starknet.common.syscalls import get_caller_address
from starkware.cairo.common.math import assert_nn_le, assert_lt, assert_le, assert_not_zero, assert_lt_felt, unsigned_div_rem
from starkware.cairo.common.registers import get_fp_and_pc
from starkware.cairo.common.alloc import alloc

from starkware.cairo.common.bitwise import bitwise_and


@contract_interface
namespace IBriqBackendContract:
    func transferFT(sender: felt, recipient: felt, material: felt, qty: felt):
    end
    func transferOneNFT(sender: felt, recipient: felt, material: felt, briq_token_id: felt):
    end
end


############
############
############
# Storage variables.

@storage_var
func _owner(token_id: felt) -> (owner: felt):
end

# To save on gas costs, the LSB of the token_uri can be 1 to indicate extra data is present. A 0 indicates no extra data.
@storage_var
func _token_uri(token_id: felt) -> (token_uri: felt):
end

@storage_var
func _token_uri_extra(token_id: felt, index: felt) -> (uri_data: felt):
end

@storage_var
func _balance(owner: felt) -> (balance: felt):
end

@storage_var
func _token_by_owner(owner: felt, index: felt) -> (token_id: felt):
end


## Utility

@storage_var
func _briq_backend_address() -> (address: felt):
end

@storage_var
func _proxy_address() -> (address: felt):
end

############
############
############
# Admin functions

func _onlyProxy{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    } ():
    let (caller) = get_caller_address()
    let (proxy) = _proxy_address.read()
    assert caller = proxy
    return ()
end

@constructor
func constructor{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    } (proxy_address: felt):
    setProxyAddress(proxy_address)
    return ()
end

##

@external
func setProxyAddress{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    } (address: felt):
    _onlyProxy()
    _proxy_address.write(address)
    return ()
end

@external
func setBriqBackendAddress{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    } (address: felt):
    _onlyProxy()
    _briq_backend_address.write(address)
    return ()
end

############
############
############
# Public functions - no authentication required

@view
func balanceOf{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    } (owner: felt) -> (balance: felt):
    let (balance) = _balance.read(owner)
    return (balance)
end

func _NFTBalanceDetailsOfIdx{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    } (owner: felt, index: felt, nft_ids: felt*) -> (tokenIds: felt*):
    let (token_id) = _token_by_owner.read(owner, index)
    if token_id == 0:
        return (nft_ids)
    end
    nft_ids[0] = token_id
    return _NFTBalanceDetailsOfIdx(owner, index + 1, nft_ids + 1)
end

@view
func balanceDetailsOf{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    } (owner: felt) -> (token_ids_len: felt, token_ids: felt*):
    alloc_locals
    let (local nfts: felt*) = alloc()
    let (nfts_full) = _NFTBalanceDetailsOfIdx(owner, 0, nfts)
    return (nfts_full - nfts, nfts)
end

# We don't implement full enumerability, just per-user
@view
func tokenOfOwnerByIndex{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    } (owner: felt, index: felt) -> (token_id: felt):
    let (token_id) = _token_by_owner.read(owner, index)
    return (token_id)
end

@view
func ownerOf{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    } (token_id: felt) -> (owner: felt):
    let (res) = _owner.read(token_id)
    return (res)
end

func _fetchExtraUri{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        bitwise_ptr: BitwiseBuiltin*,
        range_check_ptr
    } (token_id: felt, index: felt, res: felt*) -> (nb: felt):
    let (tok) = _token_uri_extra.read(token_id, index)
    let (extra) = bitwise_and(tok, 1)
    if extra == 0:
        tempvar calc = tok / 2
        res[0] = calc
        return (index)
    end
    tempvar calc = (tok - 1) / 2
    res[0] = calc
    return _fetchExtraUri(token_id, index + 1, res + 1)
end

@view
func tokenUri{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        bitwise_ptr: BitwiseBuiltin*,
        range_check_ptr
    } (token_id: felt) -> (uri_len: felt, uri: felt*):
    alloc_locals
    let (tok) = _token_uri.read(token_id)
    let (extra) = bitwise_and(tok, 1)
    let (local res: felt*) = alloc()
    if extra == 0:
        tempvar calc = tok / 2
        res[0] = calc
        return (1, res)
    end
    tempvar calc = (tok - 1)/ 2
    res[0] = calc
    let (nb_items) = _fetchExtraUri(token_id, 0, res + 1)
    return (nb_items + 2, res)
end

############
############
############
# Authenticated functions


# TODOOO -> use builtins?
func _setTokenByOwner{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    } (owner, token_id, index):

    let (tok_id) = _token_by_owner.read(owner, index)
    if tok_id == token_id:
        return()
    end
    if tok_id == 0:
        _token_by_owner.write(owner, index, token_id)
        return ()
    end
    return _setTokenByOwner(owner, token_id, index + 1)
end

# TODOOO -> use builtins?
# Step 1 -> find the target index.
func _unsetTokenByOwner_step1{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    } (owner, token_id, index) -> (target_index: felt, last_token_id: felt):
    
    let (tok_id) = _token_by_owner.read(owner, index)
    assert_not_zero(tok_id)
    if tok_id == token_id:
        return (index, token_id)
    end
    return _unsetTokenByOwner_step1(owner, token_id, index + 1)
end

# Step 2 -> once we're past the end, get the last item
func _unsetTokenByOwner_step2{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    } (owner: felt, index: felt, last_token_id: felt) -> (last_index: felt, last_token_id: felt):
    let (tok_id) = _token_by_owner.read(owner, index)
    if tok_id == 0:
        return (index - 1, last_token_id)
    end
    return _unsetTokenByOwner_step2(owner, index + 1, tok_id)
end

func _unsetTokenByOwner{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    } (owner: felt, token_id: felt):
    alloc_locals

    let (local target_index, last_token_id) = _unsetTokenByOwner_step1(owner, token_id, 0)
    let (last_index, last_token_id) = _unsetTokenByOwner_step2(owner, target_index + 1, last_token_id)
    if last_index == target_index:
        _token_by_owner.write(owner, target_index, 0)
    else:
        _token_by_owner.write(owner, target_index, last_token_id)
        _token_by_owner.write(owner, last_index, 0)
    end
    return()
end

############
############
# Assembly/Disassembly

from contracts.types import (FTSpec)

func _transferFT{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    } (owner: felt, token_id: felt, index: felt, fts: FTSpec*):
    if index == 0:
        return()
    end
    let (address) = _briq_backend_address.read()
    IBriqBackendContract.transferFT(address, owner, token_id, fts[index - 1].token_id, fts[index - 1].qty)
    return _transferFT(owner, token_id, index - 1, fts)
end


func _transferNFT{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    } (owner: felt, token_id: felt, index: felt, nfts: felt*):
    if index == 0:
        return()
    end
    let (address) = _briq_backend_address.read()
    let (uid, material) = unsigned_div_rem(nfts[index - 1], 2**64)
    IBriqBackendContract.transferOneNFT(address, owner, token_id, material, nfts[index - 1])
    return _transferNFT(owner, token_id, index - 1, nfts)
end

@external
func assemble{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    } (owner: felt, token_id: felt, fts_len: felt, fts: FTSpec*, nfts_len: felt, nfts: felt*):
    _onlyProxy()
    
    assert_not_zero(token_id)
    assert_not_zero(owner)

    let (curr_owner) = _owner.read(token_id)
    assert curr_owner = 0
    _owner.write(token_id, owner)

    _transferFT(owner, token_id, fts_len, fts)
    _transferNFT(owner, token_id, nfts_len, nfts)

    let (balance) = _balance.read(owner)
    _balance.write(owner, balance + 1)

    _setTokenByOwner(owner, token_id, 0)
    return ()
end


@external
func disassemble{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    } (owner: felt, token_id: felt, fts_len: felt, fts: FTSpec*, nfts_len: felt, nfts: felt*):
    alloc_locals
    _onlyProxy()
    
    assert_not_zero(token_id)
    assert_not_zero(owner)

    
    let (local curr_owner) = _owner.read(token_id)
    assert_not_zero(curr_owner)
    _owner.write(token_id, 0)

    _transferFT(token_id, curr_owner, fts_len, fts)
    _transferNFT(token_id, curr_owner, nfts_len, nfts)

    let (balance) = _balance.read(owner)
    _balance.write(owner, balance - 1)

    _unsetTokenByOwner(owner, token_id)
    return ()
end

func _setExtraTokenUri{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        bitwise_ptr: BitwiseBuiltin*,
        range_check_ptr
    } (token_id: felt, max: felt, index: felt, uri: felt*):
    assert_lt_felt(uri[0], 2**250)
    if max == index:
        _token_uri_extra.write(token_id, index, uri[0] * 2)
        return()
    end
    _token_uri_extra.write(token_id, index, uri[0] * 2 + 1)
    return _setExtraTokenUri(token_id, max, index + 1, uri + 1)
end

@external
func setTokenUri{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        bitwise_ptr: BitwiseBuiltin*,
        range_check_ptr
    } (token_id: felt, uri_len: felt, uri: felt*):
    _onlyProxy()
    assert_not_zero(uri_len)
    
    let (tok) = _token_uri.read(token_id)
    let (extra) = bitwise_and(tok, 1)
    assert_lt_felt(uri[0], 2**250)
    if uri_len == 1:
        _token_uri.write(token_id, uri[0] * 2)
        return ()
    end
    _token_uri.write(token_id, uri[0] * 2 + 1)
    _setExtraTokenUri(token_id, uri_len - 2, 0, uri + 1)
    return()
end

############
############
# Transfer

@external
func transferOneNFT{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    } (sender: felt, recipient: felt, token_id: felt):
    _onlyProxy()

    let (curr_owner) = _owner.read(token_id)
    assert sender = curr_owner
    _owner.write(token_id, recipient)

    let (balance) = _balance.read(sender)
    _balance.write(sender, balance - 1)
    let (balance) = _balance.read(recipient)
    _balance.write(recipient, balance + 1)

    _setTokenByOwner(recipient, token_id, 0)
    _unsetTokenByOwner(sender, token_id)
    return ()
end

