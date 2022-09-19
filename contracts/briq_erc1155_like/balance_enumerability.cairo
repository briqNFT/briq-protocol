%lang starknet

from starkware.cairo.common.math import assert_not_zero, assert_lt_felt
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.alloc import alloc

from contracts.types import BalanceSpec

// NB: this is not the total supply of any given token, and we don't store that.
@storage_var
func _total_supply(material: felt) -> (res: felt) {
}

// NB -> For now, this only stores the balance of fungible tokens (see below)
// @storage_var
// func _balance(owner: felt, token_id: felt) -> (res: felt):
// end
from contracts.library_erc1155.balance_only import _balance

@storage_var
func _owner(token_id: felt) -> (owner: felt) {
}

// We allow enumerating briq_token_ids per owner/material, but not other things.
// The list of plausible materials is not kept here.
// NB: the FT token is not listed.
@storage_var
func _token_by_owner(owner: felt, material: felt, index: felt) -> (token_id: felt) {
}

// Enumerate materials per owner.
// TODO: consider extending with the # of briqs per material, since material is 0-2^64
@storage_var
func _material_by_owner(owner: felt, index: felt) -> (material: felt) {
}

@view
func ownerOf_{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(token_id: felt) -> (
    owner: felt
) {
    let (res) = _owner.read(token_id);
    // Unlike the ERC1155 standard, don't assert that token_id != 0. This will just return 0.
    return (res,);
}

@view
func balanceOfMaterial_{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    owner: felt, material: felt
) -> (balance: felt) {
    let (nft_balance) = _balanceOfMaterialNFT(owner, material, 0, 0);
    let (ft_balance) = _balance.read(owner, material);
    return (nft_balance + ft_balance,);
}

// NB: not as fast as regular ERCs because we recompute the balance dynamically.
// TODO: is that a good idea?
func _balanceOfMaterialNFT{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    owner: felt, material: felt, index: felt, balance: felt
) -> (balance: felt) {
    let (token_id) = _token_by_owner.read(owner, material, index);
    if (token_id == 0) {
        return (balance,);
    }
    return _balanceOfMaterialNFT(owner, material, index + 1, balance + 1);
}

@view
func balanceOfMaterials_{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    owner: felt, materials_len: felt, materials: felt*
) -> (balances_len: felt, balances: felt*) {
    alloc_locals;
    let (local bals: felt*) = alloc();
    _balanceOfMaterialsImpl(owner, materials_len, materials, bals);
    return (materials_len, bals);
}

func _balanceOfMaterialsImpl{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    owner: felt, index: felt, materials: felt*, output: felt*
) {
    if (index == 0) {
        return ();
    }
    let (balance) = balanceOfMaterial_(owner, materials[0]);
    output[0] = balance;
    return _balanceOfMaterialsImpl(owner, index - 1, materials + 1, output + 1);
}

@view
func materialsOf_{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(owner: felt) -> (
    materials_len: felt, materials: felt*
) {
    alloc_locals;
    let (local mat_ids: felt*) = alloc();
    return _materialsOfImpl(owner, mat_ids, 0);
}

func _materialsOfImpl{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    owner: felt, mat_ids: felt*, index: felt
) -> (materials_len: felt, materials: felt*) {
    let (mat) = _material_by_owner.read(owner, index);
    if (mat != 0) {
        [mat_ids] = mat;
        return _materialsOfImpl(owner, mat_ids + 1, index + 1);
    }
    return (index, mat_ids - index);
}

@view
func balanceDetailsOfMaterial_{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    owner: felt, material: felt
) -> (ft_balance: felt, nft_ids_len: felt, nft_ids: felt*) {
    alloc_locals;
    let (local nfts: felt*) = alloc();
    let (nfts_full) = _balanceDetailsOfMaterialNFT(owner, material, 0, nfts);
    let (ft_balance) = _balance.read(owner, material);
    return (ft_balance, nfts_full - nfts, nfts);
}

func _balanceDetailsOfMaterialNFT{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    owner: felt, material: felt, index: felt, nft_ids: felt*
) -> (nft_ids: felt*) {
    let (token_id) = _token_by_owner.read(owner, material, index);
    if (token_id == 0) {
        return (nft_ids,);
    }
    nft_ids[0] = token_id;
    return _balanceDetailsOfMaterialNFT(owner, material, index + 1, nft_ids + 1);
}

// NB: slightly less efficient than doing it manually.
@view
func fullBalanceOf_{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    owner: felt
) -> (balances_len: felt, balances: BalanceSpec*) {
    alloc_locals;
    let (local bals: BalanceSpec*) = alloc();
    return _fullBalanceOfImpl(owner, 0, bals);
}

func _fullBalanceOfImpl{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    owner: felt, index: felt, bals: BalanceSpec*
) -> (balances_len: felt, balances: BalanceSpec*) {
    alloc_locals;

    let (mat) = _material_by_owner.read(owner, index);
    if (mat == 0) {
        return (index, bals - index * BalanceSpec.SIZE);
    }
    bals[0].material = mat;
    let (balance) = balanceOfMaterial_(owner, mat);
    bals[0].balance = balance;
    return _fullBalanceOfImpl(owner, index + 1, bals + BalanceSpec.SIZE);
}

// We don't implement full enumerability, just per-user
@view
func tokenOfOwnerByIndex_{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    owner: felt, material: felt, index: felt
) -> (token_id: felt) {
    let (token_id) = _token_by_owner.read(owner, material, index);
    return (token_id,);
}

@view
func totalSupplyOfMaterial_{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    material: felt
) -> (supply: felt) {
    let (res) = _total_supply.read(material);
    return (res,);
}

//##############
//##############
// Token setting helpers

// TODOOO -> use builtins?
// Store the new token id in the list, at an empty slot (marked by 0).
// If the item already exists in the list, do nothing.
func _setTokenByOwner{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    owner, material, briq_token_id, index
) {
    let (token_id) = _token_by_owner.read(owner, material, index);
    if (token_id == briq_token_id) {
        return ();
    }
    if (token_id == 0) {
        _token_by_owner.write(owner, material, index, briq_token_id);
        return ();
    }
    return _setTokenByOwner(owner, material, briq_token_id, index + 1);
}

// Unset the token id from the list. Swap and pop idiom.
// NB: the item is asserted to be in the list.
func _unsetTokenByOwner{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    owner, material, briq_token_id
) {
    return _unsetTokenByOwner_searchPhase(owner, material, briq_token_id, 0);
}

// During the search phase, we check for a matching token ID.
func _unsetTokenByOwner_searchPhase{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}(owner, material, briq_token_id, index) {
    let (tok) = _token_by_owner.read(owner, material, index);
    assert_not_zero(tok);
    if (tok == briq_token_id) {
        return _unsetTokenByOwner_erasePhase(owner, material, 0, index + 1, index);
    }
    return _unsetTokenByOwner_searchPhase(owner, material, briq_token_id, index + 1);
}

// During the erase phase, we pass the last known value and the slot to insert it in, and go one past the end.
func _unsetTokenByOwner_erasePhase{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    owner, material, last_known_value, index, target_index
) {
    let (tok) = _token_by_owner.read(owner, material, index);
    if (tok == 0) {
        assert_lt_felt(target_index, index);
        _token_by_owner.write(owner, material, target_index, last_known_value);
        _token_by_owner.write(owner, material, index - 1, 0);
        return ();
    }
    return _unsetTokenByOwner_erasePhase(owner, material, tok, index + 1, target_index);
}

// Same function but without the material to enumerate materials.
func _setMaterialByOwner{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    owner, material, index
) {
    let (token_id) = _material_by_owner.read(owner, index);
    if (token_id == material) {
        return ();
    }
    if (token_id == 0) {
        _material_by_owner.write(owner, index, material);
        return ();
    }
    return _setMaterialByOwner(owner, material, index + 1);
}

// Unset the material from the list if the balance is 0. Swap and pop idiom.
// NB: the item is asserted to be in the list.
func _maybeUnsetMaterialByOwner{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    owner, material
) {
    let (ft_balance) = _balance.read(owner, material);
    if (ft_balance != 0) {
        return ();
    }
    let (nft_balance) = _balanceOfMaterialNFT(owner, material, 0, 0);
    if (nft_balance != 0) {
        return ();
    }
    return _unsetMaterialByOwner_searchPhase(owner, material, 0);
}

// During the search phase, we check for a matching token ID.
func _unsetMaterialByOwner_searchPhase{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}(owner, material_id, index) {
    let (tok) = _material_by_owner.read(owner, index);
    assert_not_zero(tok);
    if (tok == material_id) {
        return _unsetMaterialByOwner_erasePhase(owner, 0, index + 1, index);
    }
    return _unsetMaterialByOwner_searchPhase(owner, material_id, index + 1);
}

// During the erase phase, we pass the last known value and the slot to insert it in, and go one past the end.
func _unsetMaterialByOwner_erasePhase{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}(owner, last_known_value, index, target_index) {
    let (tok) = _material_by_owner.read(owner, index);
    if (tok == 0) {
        assert_lt_felt(target_index, index);
        _material_by_owner.write(owner, target_index, last_known_value);
        _material_by_owner.write(owner, index - 1, 0);
        return ();
    }
    return _unsetMaterialByOwner_erasePhase(owner, tok, index + 1, target_index);
}
