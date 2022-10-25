%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin, SignatureBuiltin, BitwiseBuiltin
from starkware.cairo.common.math import assert_le_felt, assert_not_zero
from starkware.cairo.common.math_cmp import is_le_felt
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.bitwise import bitwise_and
from starkware.cairo.common.hash_state import HashState, hash_init, hash_update_single, hash_finalize, hash_felts
from starkware.starknet.common.syscalls import get_caller_address

from contracts.utilities.authorization import _onlyAdmin

from contracts.types import FTSpec, ShapeItem

from contracts.booklet_nft.token_uri import get_shape_contract_
from contracts.library_erc1155.balance import ERC1155_balance
from contracts.library_erc1155.transferability import ERC1155_transferability

from contracts.ecosystem.genesis_collection import GENESIS_COLLECTION

from contracts.ecosystem.to_attributes_registry import (
    _onlyAttributesRegistry
)

@contract_interface
namespace IShapeContract {
    func _shape() -> (shape_len: felt, shape: ShapeItem*, nfts_len: felt, nfts: felt*) {
    }

    func check_shape_numbers_(
        index: felt, shape_len: felt, shape: ShapeItem*, fts_len: felt, fts: FTSpec*, nfts_len: felt, nfts: felt*
    ) {
    }
}

@storage_var
func _shape_hash(token_id: felt) -> (shape_hash: felt) {
}

//###########
//###########

@external
func assign_attribute{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr, bitwise_ptr: BitwiseBuiltin*
}(
    owner: felt,
    set_token_id: felt,
    attribute_id: felt,
    shape_len: felt, shape: ShapeItem*,
    fts_len: felt, fts: FTSpec*,
    nfts_len: felt, nfts: felt*,
) {
    alloc_locals;

    _onlyAttributesRegistry();

    with_attr error_message("Shape cannot be empty") {
        assert_not_zero(shape_len);
    }

    let (hash_state_ptr: HashState*) = hash_init();

    let (qty: felt*) = alloc();
    let (qty_end) = _initialize_qty(fts_len, fts, qty);
    let (hash_state_ptr) = _check_shape_numbers_impl_(hash_state_ptr, shape_len, shape, fts_len, fts, qty_end - fts_len, nfts_len, nfts);

    let (hash) = hash_finalize{hash_ptr=pedersen_ptr}(hash_state_ptr=hash_state_ptr);

    _shape_hash.write(set_token_id, hash);

    return ();
}

@external
func remove_attribute{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr, bitwise_ptr: BitwiseBuiltin*
}(
    owner: felt,
    set_token_id: felt,
    attribute_id: felt,
) {
    _onlyAttributesRegistry();

    _shape_hash.write(set_token_id, 0);

    return ();
}

@view
func balanceOf_{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    token_id: felt, attribute_id: felt
) -> (balance: felt) {
    let (hash_shape) = _shape_hash.read(token_id);
    if (hash_shape == 0) {
        return (0,);
    }
    return (1,);
}

@view
func getShapeHash_{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    token_id: felt,
) -> (shape_hash: felt) {
    let (shape_hash) = _shape_hash.read(token_id);
    with_attr error_message("Unknown token ID - set shape hash is not stored.") {
        assert_not_zero(shape_hash);
    }
    return (shape_hash,);
}


@view
func checkShape_{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    token_id: felt,
    shape_len: felt, shape: ShapeItem*,
) -> (shape_matches: felt) {
    alloc_locals;
    let (shape_hash) = _shape_hash.read(token_id);
    with_attr error_message("Unknown token ID - set shape hash is not stored.") {
        assert_not_zero(shape_hash);
    }

    let (hash) = hash_felts{hash_ptr=pedersen_ptr}(shape, shape_len * ShapeItem.SIZE);
    if (hash == shape_hash) {
        return (1,);
    }
    return (0,);
}

////////////////////////////////////////////////
////////////////////////////////////////////////


func _initialize_qty{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, bitwise_ptr: BitwiseBuiltin*, range_check_ptr
}(fts_len: felt, fts: FTSpec*, qty: felt*) -> (qty_end: felt*) {
    if (fts_len == 0) {
        return (qty,);
    }
    assert qty[0] = fts[0].qty;
    let t = qty[0];
    return _initialize_qty(fts_len - 1, fts + FTSpec.SIZE, qty + 1);
}

func _check_qty_are_correct{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, bitwise_ptr: BitwiseBuiltin*, range_check_ptr
}(fts_len: felt, qty: felt*) -> () {
    if (fts_len == 0) {
        return ();
    }
    assert qty[0] = 0;
    return _check_qty_are_correct(fts_len - 1, qty + 1);
}

func _check_shape_numbers_impl_{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, bitwise_ptr: BitwiseBuiltin*, range_check_ptr
}(
    hash_state_ptr: HashState*,
    shape_len: felt,
    shape: ShapeItem*,
    fts_len: felt,
    fts: FTSpec*,
    qty: felt*,
    nfts_len: felt,
    nfts: felt*,
) -> (hash_state_ptr: HashState*) {
    alloc_locals;
    if (shape_len == 0) {
        with_attr error_message("Wrong number of briqs in shape") {
            _check_qty_are_correct(fts_len, qty);
            assert nfts_len = 0;
        }
        return (hash_state_ptr,);
    }
    
    let (hash_state_ptr) = hash_update_single{hash_ptr=pedersen_ptr}(hash_state_ptr, shape[0].color_nft_material);
    let (hash_state_ptr) = hash_update_single{hash_ptr=pedersen_ptr}(hash_state_ptr, shape[0].x_y_z);

    let nft = is_le_felt(2 ** 250 + 2**249, ((2**129-1) / 2**130) - (shape[0].color_nft_material / 2**130));
    if (nft == 1) {
        return _check_shape_numbers_impl_(
            hash_state_ptr,
            shape_len - 1,
            shape + ShapeItem.SIZE,
            fts_len,
            fts,
            qty,
            nfts_len - 1,
            nfts + 1,
        );
    } else {
        // Find the material
        // NB: using a bitwise here is somewhat balanced with the cairo steps & range comparisons,
        // and so it ends up being more gas efficient than doing the is_le_felt trick.
        let (mat) = bitwise_and(shape[0].color_nft_material, 2 ** 64 - 1);
        assert_not_zero(mat);
        // Decrement the appropriate counter
        _decrement_ft_qty(fts_len, fts, qty, mat, remaining_ft_to_parse=fts_len);
        return _check_shape_numbers_impl_(
            hash_state_ptr,
            shape_len - 1,
            shape + ShapeItem.SIZE,
            fts_len,
            fts,
            qty + fts_len,
            nfts_len,
            nfts,
        );
    }
}

// We need to keep a counter for each material we run into.
// But because of immutability, we'll need to copy the full vector of materials every time.
func _decrement_ft_qty{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, bitwise_ptr: BitwiseBuiltin*, range_check_ptr
}(fts_len: felt, fts: FTSpec*, qty: felt*, material: felt, remaining_ft_to_parse: felt) {
    if (remaining_ft_to_parse == 0) {
        // Ensure we found the material
        with_attr error_message("Material not found in FT list") {
            assert material = 0;
        }
        return ();
    }
    if (material == fts[0].token_id) {
        assert qty[fts_len] = qty[0] - 1;
        // Switch to 0 to mark we found the material
        return _decrement_ft_qty(fts_len, fts + FTSpec.SIZE, qty + 1, 0, remaining_ft_to_parse - 1);
    } else {
        assert qty[fts_len] = qty[0];
        return _decrement_ft_qty(
            fts_len, fts + FTSpec.SIZE, qty + 1, material, remaining_ft_to_parse - 1
        );
    }
}
