%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin, BitwiseBuiltin
from starkware.cairo.common.math import (
    assert_nn_le,
    assert_lt,
    assert_le,
    assert_not_zero,
    assert_lt_felt,
    unsigned_div_rem,
)
from starkware.cairo.common.math import split_felt
from starkware.cairo.common.math_cmp import is_le_felt
from starkware.cairo.common.uint256 import Uint256, uint256_check
from starkware.cairo.common.alloc import alloc

const high_bit_max = 0x8000000000000110000000000000000;

func _check_uint_fits_felt{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    value: Uint256
) {
    let high_clear = is_le_felt(value.high, high_bit_max - 1);
    // Only one possible value otherwise, the actual PRIME - 1;
    if (high_clear == 0) {
        assert value.high = high_bit_max;
        assert value.low = 0;
    }
    return ();
}


func _uint_to_felt{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    value: Uint256
) -> (value: felt) {
    uint256_check(value);
    _check_uint_fits_felt(value);
    return (value.high * (2 ** 128) + value.low,);
}

func _felt_to_uint{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    value: felt
) -> (value: Uint256) {
    let (high, low) = split_felt(value);
    tempvar res: Uint256;
    res.high = high;
    res.low = low;
    return (res,);
}


func _uints_to_felts{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    value_len: felt, value: Uint256*
) -> (value_len: felt, value: felt*) {
    alloc_locals;
    let (out: felt*) = alloc();
    _uints_to_felts_inner(value_len, value, out);
    return (value_len, out);
}


func _uints_to_felts_inner{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    value_len: felt, value: Uint256*, out: felt*
) {
    if (value_len == 0) {
        return ();
    }
    let v = value[0];
    uint256_check(v);
    _check_uint_fits_felt(v);
    assert out[0] = v.high * (2 ** 128) + v.low;
    return _uints_to_felts_inner(value_len - 1, value + 2, out + 1);
}


func _felts_to_uints{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    value_len: felt, value: felt*
) -> (value_len: felt, value: Uint256*) {
    alloc_locals;
    let (out: Uint256*) = alloc();
    _felts_to_uints_inner(value_len, value, out);
    return (value_len, out);
}

func _felts_to_uints_inner{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    value_len: felt, value: felt*, out: Uint256*
) {
    if (value_len == 0) {
        return ();
    }
    let v = value[0];
    let (high, low) = split_felt(v);
    assert out[0].high = high;
    assert out[0].low = low;
    return _felts_to_uints_inner(value_len - 1, value + 1, out + 2);
}
