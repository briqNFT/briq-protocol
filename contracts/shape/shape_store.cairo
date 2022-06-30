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

# For reference, see also cairo-based uncompression below.
struct UncompressedShapeItem:
    member material: felt
    member color: felt
    member x: felt
    member y: felt
    member z: felt
    member nft_token_id: felt
end

#DEFINE_SHAPE

@constructor
func constructor{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        bitwise_ptr: BitwiseBuiltin*,
        range_check_ptr
    } ():
    alloc_locals

    let (local shape_len, shape, nfts_len, nfts) = _shape()
    # Validate that SHAPE_LEN is accurate
    with_attr error_message("SHAPE_LEN constants and shape data length do not match"):
        let (data_address) = get_label_location(shape_data)
        let (end_data) = get_label_location(shape_data_end)
        assert SHAPE_LEN = (end_data - data_address) / ShapeItem.SIZE
    end
    # Validate that the shape has no NFT/position duplicates
    with_attr error_message("Shape items contains duplicate position or NFTs"):
        _check_for_duplicates(shape_len, shape, nfts_len, nfts)
    end
    # Validate that the shape is passed properly sorted
    with_attr error_message("Shape items are not properly sorted (increasing X/Y/Z)"):
        _check_properly_sorted(shape_len, shape)
    end
    # Validate that there are the right number/material of NFTs
    _check_nfts_ok(shape_len, shape, nfts_len, nfts)
    return ()
end

@view
func _shape{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    } () -> (shape_len: felt, shape: ShapeItem*, nfts_len: felt, nfts: felt*):
    let (_shape_data_start) = get_label_location(shape_data)
    let (_shape_data_end) = get_label_location(shape_data_end)

    let (_nft_data_start) = get_label_location(nft_data)
    let (_nft_data_end) = get_label_location(nft_data_end)

    return (
        (_shape_data_end - _shape_data_start) / ShapeItem.SIZE, cast(_shape_data_start, ShapeItem*),
        (_nft_data_end - _nft_data_start), cast(_nft_data_start, felt*),
    )
end

#@view
func compute_shape_hash{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, bitwise_ptr: BitwiseBuiltin*, range_check_ptr
    } ():
    return ()
end

# Iterate through positions until we find the right one, incrementing the NFT counter so we return the correct ID.
func _find_nft{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, bitwise_ptr: BitwiseBuiltin*, range_check_ptr
    } (x_y_z: felt, current_item: ShapeItem*, nft_index: felt) -> (token_id: felt):
    if current_item.x_y_z == x_y_z:
        let (data_address) = get_label_location(nft_data)
        let value = [data_address + nft_index]
        return (value)
    end
    let (nft) = bitwise_and(current_item.color_nft_material, 2**128)
    if nft == 2**128:
        return _find_nft(x_y_z, current_item + ShapeItem.SIZE, nft_index + 1)
    else:
        return _find_nft(x_y_z, current_item + ShapeItem.SIZE, nft_index)
    end
end

@view
func decompress_data{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, bitwise_ptr: BitwiseBuiltin*, range_check_ptr
    } (data: ShapeItem) -> (data: UncompressedShapeItem):
    let (nft) = bitwise_and(data.color_nft_material, 2**128)
    if nft != 2**128:
        let (color) = bitwise_and(data.color_nft_material, 2**251 - 1 - 2**136 + 1)
        let (material) = bitwise_and(data.color_nft_material, 2**64 - 1)
        let (x) = bitwise_and(data.x_y_z, 2**251 - 1 - 2**128 + 1)
        let (y) = bitwise_and(data.x_y_z, 2**128 - 1 - 2**64 + 1)
        let (z) = bitwise_and(data.x_y_z, 2**64 - 1)
        tempvar out = UncompressedShapeItem(material, color / 2 ** 136, x / 2 ** 128 - 0x8000000000000000, y / 2 ** 64 - 0x8000000000000000, z - 0x8000000000000000, nft)
        return (out)
    end
    let (data_address) = get_label_location(shape_data)
    let (token_id) = _find_nft(data.x_y_z, cast(data_address, ShapeItem*), 0)
    let (color) = bitwise_and(data.color_nft_material, 2**251 - 1 - 2**136 + 1)
    let (material) = bitwise_and(data.color_nft_material, 2**64 - 1)
    let (x) = bitwise_and(data.x_y_z, 2**251 - 1 - 2**128 + 1)
    let (y) = bitwise_and(data.x_y_z, 2**128 - 1 - 2**64 + 1)
    let (z) = bitwise_and(data.x_y_z, 2**64 - 1)
    tempvar out = UncompressedShapeItem(material, color / 2 ** 136, x / 2 ** 128 - 0x8000000000000000, y / 2 ** 64 - 0x8000000000000000, z - 0x8000000000000000, token_id)
    return (out)
end


# This is a complete check function. Takes a number of FT/NFTs, and a shape, and asserts that it all matches
# the shape currently stored in the contract.
@view
func check_shape_numbers_{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, bitwise_ptr: BitwiseBuiltin*, range_check_ptr
    } (shape_len: felt, shape: ShapeItem*, fts_len: felt, fts: FTSpec*, nfts_len: felt, nfts: felt*):
    
    with_attr error_message("Wrong number of shape items"):
        assert shape_len = SHAPE_LEN
    end

    with_attr error_message("Wrong number of NFTs"):
        let (nft_start) = get_label_location(nft_data)
        let (nft_end) = get_label_location(nft_data_end)
        assert nfts_len = nft_end - nft_start
    end

    # NB:
    # - This expects the NFTs to be sorted the same as the shape sorting,
    #   so in the same X/Y/Z order.
    # - We don't actually need to check the shape sorting or duplicate NFTs, because:
    #   - shape sorting would fail to match the target (which is sorted).
    #   - duplicated NFTs would fail to transfer.
    # - We need to make sure that the shape tokens match our numbers, so we count fungible tokens.
    #     To do that, we'll create a vector of quantities that we'll increment when iterating.
    #     For simplicity, we initialise it with the fts quantity, and decrement to 0, then just check that everything is 0.
    let (qty : felt*) = alloc()
    let (qty_end) = _initialize_qty(fts_len, fts, qty)

    let (nft_start) = get_label_location(nft_data)
    let (data_address) = get_label_location(shape_data)
    _check_shape_numbers_impl_(
        cast(data_address, ShapeItem*), cast(nft_start, felt*), shape_len, shape, fts_len, fts, qty_end - fts_len, nfts_len, nfts
    )
    return ()
end


func _initialize_qty{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        bitwise_ptr: BitwiseBuiltin*,
        range_check_ptr
    } (fts_len: felt, fts: FTSpec*, qty: felt*) -> (qty_end: felt*):
    if fts_len == 0:
        return (qty)
    end
    assert qty[0] = fts[0].qty
    let t = qty[0]
    return _initialize_qty(fts_len - 1, fts + FTSpec.SIZE, qty + 1)
end


func _check_qty_are_correct{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        bitwise_ptr: BitwiseBuiltin*,
        range_check_ptr
    } (fts_len: felt, qty: felt*) -> ():
    if fts_len == 0:
        return ()
    end
    assert qty[0] = 0
    return _check_qty_are_correct(fts_len - 1, qty + 1)
end


func _check_shape_numbers_impl_{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        bitwise_ptr: BitwiseBuiltin*,
        range_check_ptr
    } (stored_shape: ShapeItem*, stored_nfts: felt*, shape_len: felt, shape: ShapeItem*, fts_len: felt, fts: FTSpec*, qty: felt*, nfts_len: felt, nfts: felt*):
    if shape_len == 0:
        with_attr error_message("Wrong number of briqs in shape"):
            _check_qty_are_correct(fts_len, qty)
            assert nfts_len = 0
        end
        return ()
    end

    # Shape length has been asserted identical, so we just need to check that the data is identical.
    with_attr error_message("Shapes do not match"):
        assert stored_shape[0].color_nft_material = shape[0].color_nft_material
        assert stored_shape[0].x_y_z = shape[0].x_y_z
    end

    # Algorithm:
    # If the shape item is an nft, compare with the next nft in the list, if match, carry on.
    # Otherwise, decrement the corresponding FT quantity. This is O(n) because we must copy the whole vector.
    let (nft) = is_le_felt(2**250, shape[0].color_nft_material * (2**(122)))
    if nft == 1:
        # assert_non_zero nfts_len  ?
        # Check that the material matches.
        with_attr error_message("Incorrect NFT"):
            assert stored_nfts[0] = nfts[0]
            let a = shape[0].color_nft_material - nfts[0]
            let b = a / (2 ** 64)
            let (is_same_mat) = is_le_felt(b, 2**187)
            assert is_same_mat = 1
        end
        return _check_shape_numbers_impl_(stored_shape + ShapeItem.SIZE, stored_nfts + 1, shape_len - 1, shape + ShapeItem.SIZE, fts_len, fts, qty, nfts_len - 1, nfts + 1)
    else:
        # Find the material
        # NB: using a bitwise here is somewhat balanced with the cairo steps & range comparisons,
        # and so it ends up being more gas efficient than doing the is_le_felt trick.
        let (mat) = bitwise_and(shape[0].color_nft_material, 2**64 - 1)
        assert_not_zero(mat)
        # Decrement the appropriate counter
        _decrement_ft_qty(fts_len, fts, qty, mat, remaining_ft_to_parse=fts_len)
        return _check_shape_numbers_impl_(stored_shape + ShapeItem.SIZE, stored_nfts, shape_len - 1, shape + ShapeItem.SIZE, fts_len, fts, qty + fts_len, nfts_len, nfts)
    end
end

# We need to keep a counter for each material we run into.
# But because of immutability, we'll need to copy the full vector of materials every time.
func _decrement_ft_qty{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        bitwise_ptr: BitwiseBuiltin*,
        range_check_ptr
    } (fts_len: felt, fts: FTSpec*, qty: felt*, material: felt, remaining_ft_to_parse: felt):
    if remaining_ft_to_parse == 0:
        # Ensure we found the material
        with_attr error_message("Material not found in FT list"):
            assert material = 0
        end
        return ()
    end
    if material == fts[0].token_id:
        assert qty[fts_len] = qty[0] - 1
        # Switch to 0 to mark we found the material
        return _decrement_ft_qty(fts_len, fts + FTSpec.SIZE, qty + 1, 0, remaining_ft_to_parse - 1)
    else:
        assert qty[fts_len] = qty[0]
        return _decrement_ft_qty(fts_len, fts + FTSpec.SIZE, qty + 1, material, remaining_ft_to_parse - 1)
    end
end
