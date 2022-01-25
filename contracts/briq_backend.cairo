%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin, SignatureBuiltin
from starkware.starknet.common.syscalls import get_caller_address
from starkware.cairo.common.math import assert_nn_le, assert_lt, assert_le, assert_not_zero, assert_lt_felt, assert_le_felt
from starkware.cairo.common.registers import get_fp_and_pc
from starkware.cairo.common.alloc import alloc

from contracts.backend_common import (
    _onlyProxy,
    setProxyAddress
)

## Semantics:
# briq_token_id: 188 bits token_id, where 0 means 'FT' & 64 bits for material.
# owner can refer to a set token_id or a Starknet contract.

############
############
############
# Storage variables.

@storage_var
func _total_supply(material: felt) -> (res: felt):
end

# For FT, res is the quantity.
@storage_var
func _ft_balance(owner: felt, briq_token_id: felt) -> (res: felt):
end

@storage_var
func _owner(briq_token_id: felt) -> (owner: felt):
end

## Utility

@storage_var
func _set_backend_address() -> (address: felt):
end

# We allow enumerating briq_token_ids per owner/material, but not other things.
# The list of plausible materials is not kept here.
# NB: the FT token is not listed.
@storage_var
func _token_by_owner(owner: felt, material: felt, index: felt) -> (briq_token_id: felt):
end

############
############
############
# Admin functions

@constructor
func constructor{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    } (proxy_address: felt):
    setProxyAddress(proxy_address)
    return ()
end


@external
func setSetBackendAddress{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    } (address: felt):
    _onlyProxy()
    _set_backend_address.write(address)
    return ()
end


func _onlyProxyOrSet{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    } ():
    let (caller) = get_caller_address()
    let (address) = _set_backend_address.read()
    if caller == address:
        return()
    end
    _onlyProxy()
    return ()
end

############
############
############
# Public functions - no authentication required


# NB: not as fast as regular ERCs because we recompute the balance dynamically.
# TODO: is that a good idea?

func _balanceOfIdx{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    } (owner: felt, material: felt, index: felt, balance: felt) -> (balance: felt):
    let (token_id) = _token_by_owner.read(owner, material, index)
    if token_id == 0:
        return (balance)
    end
    return _balanceOfIdx(owner, material, index + 1, balance + 1)
end

@view
func balanceOf{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    } (owner: felt, material: felt) -> (balance: felt):
    let (nft_balance) = _balanceOfIdx(owner, material, 0, 0)
    let (ft_balance) = _ft_balance.read(owner, material)
    return (nft_balance + ft_balance)
end

func _NFTBalanceDetailsOfIdx{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    } (owner: felt, material: felt, index: felt, nft_ids: felt*) -> (nft_ids: felt*):
    let (token_id) = _token_by_owner.read(owner, material, index)
    if token_id == 0:
        return (nft_ids)
    end
    nft_ids[0] = token_id
    return _NFTBalanceDetailsOfIdx(owner, material, index + 1, nft_ids + 1)
end

@view
func balanceDetailsOf{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    } (owner: felt, material: felt) -> (ft_balance: felt, nft_ids_len: felt, nft_ids: felt*):
    alloc_locals
    let (local nfts: felt*) = alloc()
    let (nfts_full) = _NFTBalanceDetailsOfIdx(owner, material, 0, nfts)
    let (ft_balance) = _ft_balance.read(owner, material)
    return (ft_balance, nfts_full - nfts, nfts)
end

# We don't implement full enumerability, just per-user
@view
func tokenOfOwnerByIndex{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    } (owner: felt, material: felt, index: felt) -> (token_id: felt):
    let (token_id) = _token_by_owner.read(owner, material, index)
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

@view
func totalSupply{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    } (material: felt) -> (supply: felt):
    let (res) = _total_supply.read(material)
    return (res)
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
    } (owner, material, briq_token_id, index):

    let (token_id) = _token_by_owner.read(owner, material, index)
    if token_id == briq_token_id:
        return()
    end
    if token_id == 0:
        _token_by_owner.write(owner, material, index, briq_token_id)
        return ()
    end
    return _setTokenByOwner(owner, material, briq_token_id, index + 1)
end

# TODOOO -> use builtins?
# Step 1 -> find the target index.
func _unsetTokenByOwner_step1{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    } (owner, material, briq_token_id, index) -> (target_index: felt, last_token_id: felt):
    
    let (token_id) = _token_by_owner.read(owner, material, index)
    assert_not_zero(token_id)
    if token_id == briq_token_id:
        return (index, token_id)
    end
    return _unsetTokenByOwner_step1(owner, material, briq_token_id, index + 1)
end

# Step 2 -> once we're past the end, get the last item
func _unsetTokenByOwner_step2{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    } (owner, material, index, last_token_id) -> (last_index: felt, last_token_id: felt):
    let (token_id) = _token_by_owner.read(owner, material, index)
    if token_id == 0:
        return (index - 1, last_token_id)
    end
    return _unsetTokenByOwner_step2(owner, material, index + 1, token_id)
end

func _unsetTokenByOwner{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    } (owner, material, briq_token_id):
    alloc_locals

    let (local target_index, last_token_id) = _unsetTokenByOwner_step1(owner, material, briq_token_id, 0)
    let (last_index, last_token_id) = _unsetTokenByOwner_step2(owner, material, target_index + 1, last_token_id)
    if last_index == target_index:
        _token_by_owner.write(owner, material, target_index, 0)
    else:
        _token_by_owner.write(owner, material, target_index, last_token_id)
        _token_by_owner.write(owner, material, last_index, 0)
    end
    return()
end


@external
func mintFT{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    } (owner: felt, material: felt, qty: felt):
    _onlyProxy()
    
    assert_not_zero(qty * owner * material)

    # Update total supply.
    let (res) = _total_supply.read(material)
    _total_supply.write(material, res + qty)

    # FT conversion
    let briq_token_id = material

    let (balance) = _ft_balance.read(owner, briq_token_id)
    _ft_balance.write(owner, briq_token_id, balance + qty)
    return ()    
end


@external
func mintOneNFT{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    } (owner: felt, material: felt, uid: felt):
    _onlyProxy()

    assert_not_zero(owner * material * uid)
    assert_lt_felt(uid, 2**188)

    # Update total supply.
    let (res) = _total_supply.read(material)
    _total_supply.write(material, res + 1)

    # NFT conversion
    let briq_token_id = uid * 2**64 + material

    let (curr_owner) = _owner.read(briq_token_id)
    assert curr_owner = 0
    _owner.write(briq_token_id, owner)

    _setTokenByOwner(owner, material, briq_token_id, 0)
    return ()
end


## TODO -> mint multiple NFT

@external
func transferFT{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    } (sender: felt, recipient: felt, material: felt, qty: felt):
    _onlyProxyOrSet()
    
    assert_not_zero(qty)
    
    # FT conversion
    let briq_token_id = material

    let (balance_sender) = _ft_balance.read(sender, briq_token_id)
    assert_le(qty, balance_sender)
    _ft_balance.write(sender, briq_token_id, balance_sender - qty)
    
    let (balance) = _ft_balance.read(recipient, briq_token_id)
    _ft_balance.write(recipient, briq_token_id, balance + qty)

    return ()
end

@external
func transferOneNFT{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    } (sender: felt, recipient: felt, material: felt, briq_token_id: felt):
    _onlyProxyOrSet()

    let (curr_owner) = _owner.read(briq_token_id)
    assert sender = curr_owner
    _owner.write(briq_token_id, recipient)

    _setTokenByOwner(recipient, material, briq_token_id, 0)
    _unsetTokenByOwner(sender, material, briq_token_id)
    return ()
end

func _transferNFT{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    } (sender: felt, recipient: felt, material: felt, index: felt, nfts: felt*):
    if index == 0:
        return ()
    end
    transferOneNFT(sender, recipient, material, nfts[index - 1])
    return _transferNFT(sender, recipient, material, index - 1, nfts)
end

@external
func transferNFT{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    } (sender: felt, recipient: felt, material: felt, nfts_len: felt, nfts: felt*):
    _onlyProxy()
    _transferNFT(sender, recipient, material, nfts_len, nfts)
    return ()
end

@external
func mutateFT{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    } (owner: felt, source_material: felt, target_material: felt, qty: felt):
    _onlyProxy()
    
    assert_not_zero(qty * (source_material - target_material))

    let (balance) = _ft_balance.read(owner, source_material)
    assert_le(qty, balance)
    _ft_balance.write(owner, source_material, balance - qty)
    
    let (balance) = _ft_balance.read(owner, target_material)
    _ft_balance.write(owner, target_material, balance + qty)

    let (res) = _total_supply.read(source_material)
    _total_supply.write(source_material, res - qty)

    let (res) = _total_supply.read(target_material)
    _total_supply.write(target_material, res + qty)

    return ()
end

# The UI can potentially conflict. To avoid that situation, pass new_uid different from existing uid.
@external
func mutateOneNFT{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    } (owner: felt, source_material: felt, target_material: felt, uid: felt, new_uid: felt):
    _onlyProxy()

    assert_lt_felt(uid, 2**188)
    assert_lt_felt(new_uid, 2**188)
    assert_not_zero(source_material - target_material)

    # NFT conversion
    let briq_token_id = uid * 2**64 + source_material

    let (curr_owner) = _owner.read(briq_token_id)
    assert curr_owner = owner
    _unsetTokenByOwner(owner, source_material, briq_token_id)
    _owner.write(briq_token_id, 0)

    let (res) = _total_supply.read(source_material)
    _total_supply.write(source_material, res - 1)

    # Should probably use something else.
    mintOneNFT(owner, target_material, new_uid)

    return ()
end
