%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin, SignatureBuiltin
from starkware.starknet.common.syscalls import get_caller_address, get_contract_address
from starkware.cairo.common.math import assert_nn_le, assert_lt, assert_le, assert_not_zero, assert_lt_felt, assert_le_felt
from starkware.cairo.common.registers import get_fp_and_pc
from starkware.cairo.common.alloc import alloc

from contracts.types import (
    NFTSpec
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

# We allow enumerating briq_token_ids per owner/material, but not other things.
# The list of plausible materials is not kept here.
# NB: the FT token is not listed.
@storage_var
func _token_by_owner(owner: felt, material: felt, index: felt) -> (briq_token_id: felt):
end

# Enumerate materials per owner.
# TODO: consider extending with the # of briqs per material, since material is 0-2^64
@storage_var
func _material_by_owner(owner: felt, index: felt) -> (material: felt):
end

## Utility

@storage_var
func _set_backend_address() -> (address: felt):
end

############
############
############
# Events

## ERC1155 compatibility (without URI - there is none)

# NB: Operator is the address of the current contract.
# I don't really want to forward a semi-arbitrary operator for this.
# NB2: Mutate does two transfer events & a single Mutate event
@event
func TransferSingle(operator_: felt, from_: felt, to_: felt, id_: felt, value_: felt):
end

# When a NFT is mutated (FT are handled by Transfer)
@event
func Mutate(owner_: felt, old_id_: felt, new_id_: felt, from_material_: felt, to_material_: felt):
end

@event
func ConvertToFT(owner_: felt, material: felt, id_: felt):
end

@event
func ConvertToNFT(owner_: felt, material: felt, id_: felt):
end

############
############
############
## Authorization patterns

from contracts.authorization import (
    _only,
    _onlyAdmin,
    _onlyAdminAnd,
)

func _onlySetAnd{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    } (address: felt):
    let (caller) = get_caller_address()
    let (setaddr) = _set_backend_address.read()
    if caller == setaddr:
        return()
    end
    _only(address)
    return ()
end

############
############
############
# Admin functions

@external
func setSetAddress{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    } (address: felt):
    _onlyAdmin()
    _set_backend_address.write(address)
    return ()
end


####################
####################
####################
# Mint Contract

@storage_var
func _mint_contract() -> (address: felt):
end

@external
func setMintContract{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    } (address: felt):
    _onlyAdmin()
    _mint_contract.write(address)
    return ()
end


@view
func getMintContract{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    } () -> (address: felt):
    let (addr) = _mint_contract.read()
    return (addr)
end

func _onlyAdminAndMintContract{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    } ():
    let (address) = _mint_contract.read()
    _onlyAdminAnd(address)
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

func _multiBalanceOf{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    } (owner: felt, index: felt, materials: felt*, output: felt*):
    if index == 0:
        return ()
    end
    let (balance) = balanceOf(owner, materials[0])
    output[0] = balance
    return _multiBalanceOf(owner, index - 1, materials + 1, output + 1)
end

@view
func multiBalanceOf{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    } (owner: felt, materials_len: felt, materials: felt*) -> (balances_len: felt, balances: felt*):
    alloc_locals
    let (local bals: felt*) = alloc()
    _multiBalanceOf(owner, materials_len, materials, bals)
    return (materials_len, bals)
end

@view
func materialsOf{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    } (owner: felt) -> (materials_len: felt, materials: felt*):
    alloc_locals
    let (local mat_ids: felt*) = alloc()
    return _materialsOfImpl(owner, mat_ids, 0)
end

func _materialsOfImpl{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    } (owner: felt, mat_ids: felt*, index: felt) -> (materials_len: felt, materials: felt*):
    let (mat) = _material_by_owner.read(owner, index)
    if mat != 0:
        [mat_ids] = mat
        return _materialsOfImpl(owner, mat_ids + 1, index + 1)
    end
    return (index, mat_ids - index)
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

struct BalanceSpec:
    member material: felt
    member balance: felt
end

# NB: slightly less efficient than doing it manually.
@view
func fullBalanceOf{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    } (owner: felt) -> (balances_len: felt, balances: BalanceSpec*):
    alloc_locals
    let (local bals: BalanceSpec*) = alloc()
    return _fullBalanceOfImpl(owner, 0,  bals)
end

func _fullBalanceOfImpl{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    } (owner: felt, index: felt, bals: BalanceSpec*) -> (balances_len: felt, balances: BalanceSpec*):
    alloc_locals

    let (mat) = _material_by_owner.read(owner, index)
    if mat == 0:
        return (index, bals - index * BalanceSpec.SIZE)
    end
    bals[0].material = mat
    let (balance) = balanceOf(owner, mat)
    bals[0].balance = balance
    return _fullBalanceOfImpl(owner, index + 1, bals + BalanceSpec.SIZE)
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

########################
########################
########################
# Authenticated functions


# TODOOO -> use builtins?
# Store the new token id in the list, at an empty slot (marked by 0).
# If the item already exists in the list, do nothing.
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

# Unset the token id from the list. Swap and pop idiom.
# NB: the item is asserted to be in the list.
func _unsetTokenByOwner{
        syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
    } (owner, material, briq_token_id):
    return _unsetTokenByOwner_searchPhase(owner, material, briq_token_id, 0)
end

# During the search phase, we check for a matching token ID.
func _unsetTokenByOwner_searchPhase{
        syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
    } (owner, material, briq_token_id, index):
    let (tok) = _token_by_owner.read(owner, material, index)
    assert_not_zero(tok)
    if tok == briq_token_id:
        return _unsetTokenByOwner_erasePhase(owner, material, 0, index + 1, index)
    end
    return _unsetTokenByOwner_searchPhase(owner, material, briq_token_id, index + 1)
end

# During the erase phase, we pass the last known value and the slot to insert it in, and go one past the end.
func _unsetTokenByOwner_erasePhase{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    } (owner, material, last_known_value, index, target_index):
    let (tok) = _token_by_owner.read(owner, material, index)
    if tok == 0:
        assert_lt_felt(target_index, index)
        _token_by_owner.write(owner, material, target_index, last_known_value)
        _token_by_owner.write(owner, material, index - 1, 0)
        return ()
    end
    return _unsetTokenByOwner_erasePhase(owner, material, tok, index + 1, target_index)

# Same function but without the material to enumerate materials.
func _setMaterialByOwner{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    } (owner, material, index):

    let (token_id) = _material_by_owner.read(owner, index)
    if token_id == material:
        return()
    end
    if token_id == 0:
        _material_by_owner.write(owner, index, material)
        return ()
    end
    return _setMaterialByOwner(owner, material, index + 1)
end

# Unset the material from the list if the balance is 0. Swap and pop idiom.
# NB: the item is asserted to be in the list.
func _maybeUnsetMaterialByOwner{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    } (owner, material):

    let (ft_balance) = _ft_balance.read(owner, material)
    if ft_balance != 0:
        return ()
    end
    let (nft_balance) = _balanceOfIdx(owner, material, 0, 0)
    if nft_balance != 0:
        return ()
    end
    return _unsetMaterialByOwner_searchPhase(owner, material, 0)
end


# During the search phase, we check for a matching token ID.
func _unsetMaterialByOwner_searchPhase{
        syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
    } (owner, material_id, index):
    let (tok) = _material_by_owner.read(owner, index)
    assert_not_zero(tok)
    if tok == material_id:
        return _unsetMaterialByOwner_erasePhase(owner, 0, index + 1, index)
    end
    return _unsetMaterialByOwner_searchPhase(owner, material_id, index + 1)
end

# During the erase phase, we pass the last known value and the slot to insert it in, and go one past the end.
func _unsetMaterialByOwner_erasePhase{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    } (owner, last_known_value, index, target_index):
    let (tok) = _material_by_owner.read(owner, index)
    if tok == 0:
        assert_lt_felt(target_index, index)
        _material_by_owner.write(owner, target_index, last_known_value)
        _material_by_owner.write(owner, index - 1, 0)
        return ()
    end
    return _unsetMaterialByOwner_erasePhase(owner, tok, index + 1, target_index)
<<<<

################
################
################

@external
func mintFT{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    } (owner: felt, material: felt, qty: felt):
    _onlyAdminAndMintContract()

    assert_not_zero(owner)
    assert_not_zero(material)
    assert_not_zero(qty)

    # Update total supply.
    let (res) = _total_supply.read(material)
    _total_supply.write(material, res + qty)

    # FT conversion
    let briq_token_id = material

    let (balance) = _ft_balance.read(owner, briq_token_id)
    _ft_balance.write(owner, briq_token_id, balance + qty)

    _setMaterialByOwner(owner, material, 0)

    let (__addr) = get_contract_address()
    TransferSingle.emit(__addr, 0, owner, briq_token_id, qty)

    return ()    
end

@external
func mintOneNFT{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    } (owner: felt, material: felt, uid: felt):
    _onlyAdminAndMintContract()

    assert_not_zero(owner)
    assert_not_zero(material)
    assert_not_zero(uid)
    assert_lt_felt(uid, 2**188)

    # Update total supply.
    let (res) = _total_supply.read(material)
    _total_supply.write(material, res + 1)

    # NFT conversion
    let briq_token_id = uid * 2**64 + material

    let (curr_owner) = _owner.read(briq_token_id)
    assert curr_owner = 0
    _owner.write(briq_token_id, owner)

    _setMaterialByOwner(owner, material, 0)
    _setTokenByOwner(owner, material, briq_token_id, 0)

    let (__addr) = get_contract_address()
    TransferSingle.emit(__addr, 0, owner, briq_token_id, 1)

    return ()
end


## TODO -> mint multiple NFT

@external
func transferFT{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    } (sender: felt, recipient: felt, material: felt, qty: felt):
    _onlySetAnd(sender)
    
    assert_not_zero(sender)
    assert_not_zero(material)
    assert_not_zero(qty)
    
    # FT conversion
    let briq_token_id = material

    let (balance_sender) = _ft_balance.read(sender, briq_token_id)
    assert_le_felt(qty, balance_sender)
    _ft_balance.write(sender, briq_token_id, balance_sender - qty)
    
    let (balance) = _ft_balance.read(recipient, briq_token_id)
    _ft_balance.write(recipient, briq_token_id, balance + qty)

    _setMaterialByOwner(recipient, material, 0)
    _maybeUnsetMaterialByOwner(sender, material)

    let (__addr) = get_contract_address()
    TransferSingle.emit(__addr, sender, recipient, briq_token_id, qty)

    return ()
end

@external
func transferOneNFT{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    } (sender: felt, recipient: felt, material: felt, briq_token_id: felt):
    _onlySetAnd(sender)

    assert_not_zero(sender)
    assert_not_zero(material)
    assert_not_zero(briq_token_id)

    let (curr_owner) = _owner.read(briq_token_id)
    assert sender = curr_owner
    _owner.write(briq_token_id, recipient)

    # Unset before setting, so that self-transfers work.
    _unsetTokenByOwner(sender, material, briq_token_id)
    _setTokenByOwner(recipient, material, briq_token_id, 0)

    _maybeUnsetMaterialByOwner(sender, material) # Keep after unset token or it won't unset
    _setTokenByOwner(recipient, material, briq_token_id, 0)

    let (__addr) = get_contract_address()
    TransferSingle.emit(__addr, sender, recipient, briq_token_id, 1)

    return ()
end

func _transferNFT{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    } (sender: felt, recipient: felt, material: felt, index: felt, token_ids: felt*):
    if index == 0:
        return ()
    end
    transferOneNFT(sender, recipient, material, token_ids[index - 1])
    return _transferNFT(sender, recipient, material, index - 1, token_ids)
end

@external
func transferNFT{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    } (sender: felt, recipient: felt, material: felt, token_ids_len: felt, token_ids: felt*):
    # Calls authorized methods, no need to check here.
    _transferNFT(sender, recipient, material, token_ids_len, token_ids)
    return ()
end

@external
func mutateFT{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    } (owner: felt, source_material: felt, target_material: felt, qty: felt):
    _onlyAdmin()
    
    assert_not_zero(qty * (source_material - target_material))

    let (balance) = _ft_balance.read(owner, source_material)
    assert_le_felt(qty, balance)
    _ft_balance.write(owner, source_material, balance - qty)
    
    let (balance) = _ft_balance.read(owner, target_material)
    _ft_balance.write(owner, target_material, balance + qty)

    let (res) = _total_supply.read(source_material)
    _total_supply.write(source_material, res - qty)

    let (res) = _total_supply.read(target_material)
    _total_supply.write(target_material, res + qty)

    _setMaterialByOwner(owner, target_material, 0)
    _maybeUnsetMaterialByOwner(owner, source_material)

    let (__addr) = get_contract_address()
    TransferSingle.emit(__addr, owner, 0, source_material, qty)
    TransferSingle.emit(__addr, 0, owner, target_material, qty)

    return ()
end

# The UI can potentially conflict. To avoid that situation, pass new_uid different from existing uid.
@external
func mutateOneNFT{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    } (owner: felt, source_material: felt, target_material: felt, uid: felt, new_uid: felt):
    _onlyAdmin()

    assert_lt_felt(uid, 2**188)
    assert_lt_felt(new_uid, 2**188)
    assert_not_zero(source_material - target_material)

    # NFT conversion
    let (res) = _total_supply.read(source_material)
    _total_supply.write(source_material, res - 1)

    let briq_token_id = uid * 2**64 + source_material

    let (curr_owner) = _owner.read(briq_token_id)
    assert curr_owner = owner
    _owner.write(briq_token_id, 0)

    _unsetTokenByOwner(owner, source_material, briq_token_id)
    _maybeUnsetMaterialByOwner(owner, source_material) # Keep after unset token or it won't unset

    let (res) = _total_supply.read(target_material)
    _total_supply.write(target_material, res + 1)

    # briq_token_id is not the new ID
    let briq_token_id = new_uid * 2**64 + target_material

    let (curr_owner) = _owner.read(briq_token_id)
    assert curr_owner = 0
    _owner.write(briq_token_id, owner)

    _setMaterialByOwner(owner, target_material, 0)
    _setTokenByOwner(owner, target_material, briq_token_id, 0)

    let (__addr) = get_contract_address()
    TransferSingle.emit(__addr, owner, 0, uid * 2**64 + source_material, 1)
    TransferSingle.emit(__addr, 0, owner, new_uid * 2**64 + target_material, 1)
    Mutate.emit(owner, uid * 2**64 + source_material, new_uid * 2**64 + target_material, source_material, target_material)

    return ()
end

###############

@external
func convertOneToFT{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    } (owner: felt, material: felt, token_id: felt):
    _onlyAdmin()
    
    assert_not_zero(owner)
    assert_not_zero(token_id)

    let (curr_owner) = _owner.read(token_id)
    if curr_owner == owner:
        assert curr_owner = owner
    else:
        assert token_id = curr_owner
    end
    # No need to change material
    _unsetTokenByOwner(owner, material, token_id)
    _owner.write(token_id, 0)

    let (balance) = _ft_balance.read(owner, material)
    _ft_balance.write(owner, material, balance + 1)

    let (__addr) = get_contract_address()
    TransferSingle.emit(__addr, owner, 0, token_id, 1)
    TransferSingle.emit(__addr, 0, owner, material, 1)
    ConvertToFT.emit(owner, material, token_id)
    return ()
end

func _convertToFT{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    } (owner: felt, index: felt, nfts: NFTSpec*):
    if index == 0:
        return ()
    end
    convertOneToFT(owner, nfts[0].material, nfts[0].token_id)
    return _convertToFT(owner, index - 1, nfts + NFTSpec.SIZE)
end

@external
func convertToFT{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    } (owner: felt, token_ids_len: felt, token_ids: NFTSpec*):
    _onlyAdmin()
    
    assert_not_zero(owner)
    assert_not_zero(token_ids_len)

    _convertToFT(owner, token_ids_len, token_ids)

    return ()
end


@external
func convertOneToNFT{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    } (owner: felt, material: felt, uid: felt):
    _onlyAdmin()

    assert_not_zero(owner)
    assert_not_zero(material)
    assert_lt_felt(uid, 2**188)

    # NFT conversion
    let token_id = uid * 2**64 + material

    let (curr_owner) = _owner.read(token_id)
    assert curr_owner = 0
    _owner.write(token_id, owner)

    # No need to change material
    _setTokenByOwner(owner, material, token_id, 0)

    let (balance) = _ft_balance.read(owner, material)
    _ft_balance.write(owner, material, balance - 1)

    let (__addr) = get_contract_address()
    TransferSingle.emit(__addr, owner, 0, material, 1)
    TransferSingle.emit(__addr, 0, owner, token_id, 1)
    ConvertToNFT.emit(owner, material, token_id)

    return ()
end
