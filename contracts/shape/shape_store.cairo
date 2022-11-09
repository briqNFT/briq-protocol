%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin, SignatureBuiltin, BitwiseBuiltin
from starkware.cairo.common.registers import get_label_location
from starkware.cairo.common.math import assert_le_felt, assert_not_zero
from starkware.cairo.common.math_cmp import is_le_felt
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.bitwise import bitwise_and

from contracts.types import ShapeItem, FTSpec

from contracts.shape.construction_guards import (
    _check_properly_sorted,
    _check_for_duplicates,
    _check_nfts_ok,
)

from contracts.shape.data import (
    shape_offset_cumulative,
    shape_offset_cumulative_end,
    shape_data,
    shape_data_end,
    nft_offset_cumulative,
    nft_offset_cumulative_end,
    nft_data,
    nft_data_end,
    INDEX_START,
)

const ANY_MATERIAL_ANY_COLOR = 0;

// For reference, see also cairo-based uncompression below.
struct UncompressedShapeItem {
    material: felt,
    color: felt,
    x: felt,
    y: felt,
    z: felt,
    nft_token_id: felt,
}

// Returns the number of shapes stored in the contract data. Remove 1 because that's boundaries.
func _get_nb_shapes{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, bitwise_ptr: BitwiseBuiltin*, range_check_ptr}(
) -> felt {
    let (_shape_offset_cumulative_start) = get_label_location(shape_offset_cumulative);
    let (_shape_offset_cumulative_end) = get_label_location(shape_offset_cumulative_end);
    return _shape_offset_cumulative_end - _shape_offset_cumulative_start - 1;
}

// Returns the offsets for the i-th shape (starting from 0). End is exclusive.
func _get_shape_offsets{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, bitwise_ptr: BitwiseBuiltin*, range_check_ptr}(
    i: felt
) -> (
    start: felt*, end: felt*
) {
    let (_shape_offset_cumulative_start) = get_label_location(shape_offset_cumulative);
    let (loc) = get_label_location(shape_data);
    return (
        loc + [_shape_offset_cumulative_start + i] * ShapeItem.SIZE,
        loc + [_shape_offset_cumulative_start + i + 1] * ShapeItem.SIZE
    );
}

// Returns the offset for the i-th nft (starting from 0). End is exclusive.
func _get_nft_offsets{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, bitwise_ptr: BitwiseBuiltin*, range_check_ptr}(
    i: felt
) -> (
    start: felt*, end: felt*
) {
    let (_nft_offset_cumulative_start) = get_label_location(nft_offset_cumulative);
    let (loc) = get_label_location(nft_data);
    return (
        loc + [_nft_offset_cumulative_start + i],
        loc + [_nft_offset_cumulative_start + i + 1]
    );
}

@constructor
func constructor{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, bitwise_ptr: BitwiseBuiltin*, range_check_ptr
}() {
    _validate_nth_shape(_get_nb_shapes());
    return ();
}

// N starts at 1.
func _validate_nth_shape{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, bitwise_ptr: BitwiseBuiltin*, range_check_ptr}(
    n: felt
) {
    alloc_locals;
    if (n == 0) {
        return();
    }

    let (local shape_len, shape, nfts_len, nfts) = _shape(n - 1);

    // Validate that the shape has no NFT/position duplicates
    with_attr error_message("Shape items contains duplicate position or NFTs") {
        _check_for_duplicates(shape_len, shape, nfts_len, nfts);
    }
    // Validate that the shape is passed properly sorted
    with_attr error_message("Shape items are not properly sorted (increasing X/Y/Z)") {
        _check_properly_sorted(shape_len, shape);
    }
    // Validate that there are the right number/material of NFTs
    _check_nfts_ok(shape_len, shape, nfts_len, nfts);

    return _validate_nth_shape(n - 1);
}

func _shape{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, bitwise_ptr: BitwiseBuiltin*, range_check_ptr}(
    i: felt,
) -> (
    shape_len: felt, shape: ShapeItem*, nfts_len: felt, nfts: felt*
) {
    let (_shape_data_start, _shape_data_end) = _get_shape_offsets(i);
    let (_nft_data_start, _nft_data_end) = _get_nft_offsets(i);

    return (
        (_shape_data_end - _shape_data_start) / ShapeItem.SIZE,
        cast(_shape_data_start, ShapeItem*),
        (_nft_data_end - _nft_data_start),
        cast(_nft_data_start, felt*),
    );
}

@view
func shape_{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, bitwise_ptr: BitwiseBuiltin*, range_check_ptr}(
    global_index: felt,
) -> (
    shape_len: felt, shape: ShapeItem*, nfts_len: felt, nfts: felt*
) {
    return _shape(global_index - INDEX_START);
}

// @view
func compute_shape_hash{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, bitwise_ptr: BitwiseBuiltin*, range_check_ptr
}() {
    return ();
}

// Iterate through positions until we find the right one, incrementing the NFT counter so we return the correct ID.
func _find_nft{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, bitwise_ptr: BitwiseBuiltin*, range_check_ptr
}(x_y_z: felt, current_item: ShapeItem*, nft_ptr: felt*) -> (token_id: felt) {
    if (current_item.x_y_z == x_y_z) {
        let value = [nft_ptr];
        return (value,);
    }
    let (nft) = bitwise_and(current_item.color_nft_material, 2 ** 128);
    if (nft == 2 ** 128) {
        return _find_nft(x_y_z, current_item + ShapeItem.SIZE, nft_ptr + 1);
    } else {
        return _find_nft(x_y_z, current_item + ShapeItem.SIZE, nft_ptr);
    }
}

// Intended as mostly a 'debug' function, thus the use of local_index
@view
func decompress_data{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, bitwise_ptr: BitwiseBuiltin*, range_check_ptr
}(data: ShapeItem, local_index: felt) -> (data: UncompressedShapeItem) {
    let (nft) = bitwise_and(data.color_nft_material, 2 ** 128);
    if (nft != 2 ** 128) {
        let (color) = bitwise_and(data.color_nft_material, 2 ** 251 - 1 - 2 ** 136 + 1);
        let (material) = bitwise_and(data.color_nft_material, 2 ** 64 - 1);
        let (x) = bitwise_and(data.x_y_z, 2 ** 251 - 1 - 2 ** 128 + 1);
        let (y) = bitwise_and(data.x_y_z, 2 ** 128 - 1 - 2 ** 64 + 1);
        let (z) = bitwise_and(data.x_y_z, 2 ** 64 - 1);
        tempvar out = UncompressedShapeItem(material, color / 2 ** 136, x / 2 ** 128 - 0x8000000000000000, y / 2 ** 64 - 0x8000000000000000, z - 0x8000000000000000, nft);
        return (out,);
    }
    let (data_address, _) = _get_shape_offsets(local_index);
    let (nft_offset, _) = _get_nft_offsets(local_index);
    let (token_id) = _find_nft(data.x_y_z, cast(data_address, ShapeItem*), nft_offset);

    let (color) = bitwise_and(data.color_nft_material, 2 ** 251 - 1 - 2 ** 136 + 1);
    let (material) = bitwise_and(data.color_nft_material, 2 ** 64 - 1);
    let (x) = bitwise_and(data.x_y_z, 2 ** 251 - 1 - 2 ** 128 + 1);
    let (y) = bitwise_and(data.x_y_z, 2 ** 128 - 1 - 2 ** 64 + 1);
    let (z) = bitwise_and(data.x_y_z, 2 ** 64 - 1);
    tempvar out = UncompressedShapeItem(material, color / 2 ** 136, x / 2 ** 128 - 0x8000000000000000, y / 2 ** 64 - 0x8000000000000000, z - 0x8000000000000000, token_id);
    return (out,);
}

// This is a complete check function. Takes a number of FT/NFTs, and a shape, and asserts that it all matches
// the shape currently stored in the contract.
@view
func check_shape_numbers_{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, bitwise_ptr: BitwiseBuiltin*, range_check_ptr
}(global_index: felt, shape_len: felt, shape: ShapeItem*, fts_len: felt, fts: FTSpec*, nfts_len: felt, nfts: felt*) {
    with_attr error_message("Wrong number of shape items") {
        let (start, end) = _get_shape_offsets(global_index - INDEX_START);
        assert shape_len = (end - start) / ShapeItem.SIZE;
    }

    with_attr error_message("Wrong number of NFTs") {
        let (start, end) = _get_nft_offsets(global_index - INDEX_START);
        assert nfts_len = end - start;
    }

    // NB:
    // - This expects the NFTs to be sorted the same as the shape sorting,
    //   so in the same X/Y/Z order.
    // - We don't actually need to check the shape sorting or duplicate NFTs, because:
    //   - shape sorting would fail to match the target (which is sorted).
    //   - duplicated NFTs would fail to transfer.
    // - We need to make sure that the shape tokens match our numbers, so we count fungible tokens.
    //     To do that, we'll create a vector of quantities that we'll increment when iterating.
    //     For simplicity, we initialise it with the fts quantity, and decrement to 0, then just check that everything is 0.
    let (qty: felt*) = alloc();
    let (qty_end) = _initialize_qty(fts_len, fts, qty);

    let (nft_start, _) = _get_nft_offsets(global_index - INDEX_START);
    let (data_address, __) = _get_shape_offsets(global_index - INDEX_START);
    _check_shape_numbers_impl_(
        cast(data_address, ShapeItem*),
        cast(nft_start, felt*),
        shape_len,
        shape,
        fts_len,
        fts,
        qty_end - fts_len,
        nfts_len,
        nfts,
    );
    return ();
}

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
    stored_shape: ShapeItem*,
    stored_nfts: felt*,
    shape_len: felt,
    shape: ShapeItem*,
    fts_len: felt,
    fts: FTSpec*,
    qty: felt*,
    nfts_len: felt,
    nfts: felt*,
) {
    if (shape_len == 0) {
        with_attr error_message("Wrong number of briqs in shape") {
            _check_qty_are_correct(fts_len, qty);
            assert nfts_len = 0;
        }
        return ();
    }

    // Shape length has been asserted identical, so we just need to check that the data is identical.
    with_attr error_message("Shapes do not match") {
        if (stored_shape[0].color_nft_material != ANY_MATERIAL_ANY_COLOR) {
            assert stored_shape[0].color_nft_material = shape[0].color_nft_material;
        }
        assert stored_shape[0].x_y_z = shape[0].x_y_z;
    }

    // Algorithm:
    // If the shape item is an nft, compare with the next nft in the list, if match, carry on.
    // Otherwise, decrement the corresponding FT quantity. This is O(n) because we must copy the whole vector.
    let nft = is_le_felt(2 ** 250 + 2**249, ((2**129-1) / 2**130) - (shape[0].color_nft_material / 2**130));
    if (nft == 1) {
        // assert_non_zero nfts_len  ?
        // Check that the material matches.
        with_attr error_message("Incorrect NFT") {
            assert stored_nfts[0] = nfts[0];
            let a = shape[0].color_nft_material - nfts[0];
            let b = a / (2 ** 64);
            let is_same_mat = is_le_felt(b, 2 ** 187);
            assert is_same_mat = 1;
        }
        return _check_shape_numbers_impl_(
            stored_shape + ShapeItem.SIZE,
            stored_nfts + 1,
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
            stored_shape + ShapeItem.SIZE,
            stored_nfts,
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
