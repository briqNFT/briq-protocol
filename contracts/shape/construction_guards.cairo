%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin, SignatureBuiltin, BitwiseBuiltin
from starkware.cairo.common.math import assert_le_felt, assert_lt_felt, assert_not_zero

from starkware.cairo.common.bitwise import bitwise_and

from contracts.types import ShapeItem

@view
func _check_properly_sorted{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, bitwise_ptr: BitwiseBuiltin*, range_check_ptr
}(shape_len: felt, shape: ShapeItem*) -> () {
    if (shape_len == 0) {
        return ();
    }
    return _check_properly_sorted_impl(shape_len, shape);
}

func _check_properly_sorted_impl{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, bitwise_ptr: BitwiseBuiltin*, range_check_ptr
}(shape_len: felt, shape: ShapeItem*) -> () {
    // nothing more to sort
    if (shape_len == 1) {
        return ();
    }
    assert_lt_felt(shape[0].x_y_z, shape[1].x_y_z);
    return _check_properly_sorted_impl(shape_len - 1, shape + ShapeItem.SIZE);
}

@view
func _check_for_duplicates{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, bitwise_ptr: BitwiseBuiltin*, range_check_ptr
}(shape_len: felt, shape: ShapeItem*, nfts_len: felt, nfts: felt*) -> () {
    if (shape_len == 0) {
        assert nfts_len = 0;
        return ();
    }
    _check_for_duplicates_shape_impl(shape_len, shape);
    if (nfts_len == 0) {
        return ();
    }
    _check_for_duplicates_nfts_impl(nfts_len, nfts);
    return ();
}

func _check_for_duplicates_shape_impl{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, bitwise_ptr: BitwiseBuiltin*, range_check_ptr
}(shape_len: felt, shape: ShapeItem*) -> () {
    if (shape_len == 1) {
        return ();
    }
    if (shape[0].x_y_z == shape[1].x_y_z) {
        assert 0 = 1;
    }
    return _check_for_duplicates_shape_impl(shape_len - 1, shape + ShapeItem.SIZE);
}

func _check_for_duplicates_nfts_impl{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, bitwise_ptr: BitwiseBuiltin*, range_check_ptr
}(nfts_len: felt, nfts: felt*) -> () {
    if (nfts_len == 1) {
        return ();
    }
    _check_for_nft(nfts[0], nfts_len - 1, nfts + 1);
    _check_for_duplicates_nfts_impl(nfts_len - 1, nfts + 1);
    return ();
}

func _check_for_nft{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, bitwise_ptr: BitwiseBuiltin*, range_check_ptr
}(comp_to: felt, nfts_len: felt, nfts: felt*) -> () {
    if (nfts_len == 0) {
        return ();
    }
    assert_not_zero(comp_to - nfts[0]);
    _check_for_nft(comp_to, nfts_len - 1, nfts + 1);
    return ();
}

from starkware.cairo.common.math_cmp import is_le_felt

@view
func _check_nfts_ok{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, bitwise_ptr: BitwiseBuiltin*, range_check_ptr
}(shape_len: felt, shape: ShapeItem*, nfts_len: felt, nfts: felt*) {
    if (shape_len == 0) {
        with_attr error_message("Shape does not have the right number of NFTs") {
            assert nfts_len = 0;
        }
        return ();
    }
    // Bitwise is 255 times more costly than a cairo step and 32 times more than a range builtin,
    // so it's more efficient to use other tools. The code below has similar output to:
    // let (nft) = bitwise_and(shape[0].color_nft_material, 2**128)

    // Shift to the left - if the item is an NFT (indicated by 1 in the 128th bit),
    // then the right * 2*122 is necessarily bigger than 2**251 (the new left-most bit).
    let nft = is_le_felt(2 ** 250, shape[0].color_nft_material * (2 ** (122)));
    if (nft == 1) {
        with_attr error_message("Shape does not have the right number of NFTs") {
            assert_not_zero(nfts_len);
        }
        with_attr error_message("NFT does not have the right material") {
            // Corresponding bitwise:
            // let (material_shape) = bitwise_and(shape[0].color_nft_material, 2**64 - 1)
            // let (material_nft) = bitwise_and(nfts[0], 2**64 - 1)
            // assert material_shape = material_nft

            // Shift-right, now the top 64 bits are the material. So if the difference there is 0, we have the same material.
            // This works even if the subtraction leads to a negative number, because of the modulo wraparound.
            // (Note that I have some leeway because the color only occupies bits 136-192)
            let a = shape[0].color_nft_material - nfts[0];
            let b = a / (2 ** 64);
            let is_same_mat = is_le_felt(b, 2 ** 187);
            // %{ print(hex(ids.a - ids.b), hex(2**187), ids.is_same_mat) %}
            assert is_same_mat = 1;
        }
        return _check_nfts_ok(shape_len - 1, shape + ShapeItem.SIZE, nfts_len - 1, nfts + 1);
    } else {
        return _check_nfts_ok(shape_len - 1, shape + ShapeItem.SIZE, nfts_len, nfts);
    }
}
