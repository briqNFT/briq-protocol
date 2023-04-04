%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin, BitwiseBuiltin
from starkware.cairo.common.uint256 import Uint256

from contracts.utilities.Uint256_felt_conv import _uint_to_felt, _felt_to_uint, _uints_to_felts, _felts_to_uints

@external
func uint_to_felt{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    value: Uint256
) -> (value: felt) {
    return _uint_to_felt(value);
}

@external
func felt_to_uint{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    value: felt
) -> (value: Uint256) {
    return _felt_to_uint(value);
}

@external
func uints_to_felts{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    value_len: felt, value: Uint256*
) -> (value_len: felt, value: felt*) {
    return _uints_to_felts(value_len, value);
}

@external
func felts_to_uints{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    value_len: felt, value: felt*
) -> (value_len: felt, value: Uint256*) {
    return _felts_to_uints(value_len, value);
}
