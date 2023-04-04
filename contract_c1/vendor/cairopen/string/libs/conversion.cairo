%lang starknet

from starkware.cairo.common.cairo_builtins import BitwiseBuiltin
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.bitwise import bitwise_and
from starkware.cairo.common.math import unsigned_div_rem, assert_le, assert_lt
from starkware.cairo.common.math_cmp import is_le

from cairopen.math.array import concat_felt_arr, invert_felt_arr
from cairopen.string.string import String
from cairopen.string.constants import SHORT_STRING_MAX_VALUE, STRING_MAX_LEN

// felt to String
func conversion_felt_to_string{range_check_ptr, codec_numerical_offset}(elem: felt) -> (
    str: String
) {
    alloc_locals;
    let (local str_seed: felt*) = alloc();
    let (str_len) = _loop_felt_to_inverted_string(elem, str_seed, 0);

    let (_, str) = invert_felt_arr(str_len, str_seed);
    return (String(str_len, str),);
}

func _loop_felt_to_inverted_string{range_check_ptr, codec_numerical_offset}(
    elem: felt, str_seed: felt*, index: felt
) -> (str_len: felt) {
    alloc_locals;
    with_attr error_message("felt_to_string: exceeding max String length 2^15") {
        assert_le(index, STRING_MAX_LEN);
    }

    let (rem_elem, unit) = unsigned_div_rem(elem, 10);
    assert str_seed[index] = unit + codec_numerical_offset;
    if (rem_elem == 0) {
        return (index + 1,);
    }

    let is_lower = is_le(elem, rem_elem);
    if (is_lower != 0) {
        return (index + 1,);
    }

    return _loop_felt_to_inverted_string(rem_elem, str_seed, index + 1);
}

// short string to String
func conversion_ss_to_string{
    bitwise_ptr: BitwiseBuiltin*, range_check_ptr, codec_char_size, codec_last_char_mask
}(ss: felt) -> (str: String) {
    alloc_locals;
    let (local str_seed: felt*) = alloc();
    let (str_len) = _loop_ss_to_inverted_string(ss, str_seed, 0);

    let (_, str) = invert_felt_arr(str_len, str_seed);
    return (String(str_len, str),);
}

func _loop_ss_to_inverted_string{
    bitwise_ptr: BitwiseBuiltin*, range_check_ptr, codec_char_size, codec_last_char_mask
}(ss: felt, str_seed: felt*, index: felt) -> (str_len: felt) {
    alloc_locals;

    let (ss_rem, char) = conversion_extract_last_char_from_ss(ss);
    assert str_seed[index] = char;

    if (char == ss) {
        return (index + 1,);
    }

    let is_lower = is_le(ss, ss_rem);
    if (is_lower != 0) {
        return (index + 1,);
    }

    return _loop_ss_to_inverted_string(ss_rem, str_seed, index + 1);
}

// short string array to String
func conversion_ss_arr_to_string{
    bitwise_ptr: BitwiseBuiltin*, range_check_ptr, codec_char_size, codec_last_char_mask
}(ss_arr_len: felt, ss_arr: felt*) -> (str: String) {
    let (str_seed) = alloc();
    let (str_len, str) = _loop_ss_arr_to_string(ss_arr_len, ss_arr, 0, 0, str_seed);
    return (String(str_len, str),);
}

func _loop_ss_arr_to_string{
    bitwise_ptr: BitwiseBuiltin*, range_check_ptr, codec_char_size, codec_last_char_mask
}(ss_arr_len: felt, ss_arr: felt*, ss_index: felt, prev_str_len: felt, prev_str: felt*) -> (
    str_len: felt, str: felt*
) {
    alloc_locals;

    let (local ss_str_seed: felt*) = alloc();
    let (ss_str_len) = _loop_ss_to_inverted_string(ss_arr[ss_index], ss_str_seed, 0);
    let (_, str_str) = invert_felt_arr(ss_str_len, ss_str_seed);

    let (str_len, str) = concat_felt_arr(prev_str_len, prev_str, ss_str_len, str_str);
    if (ss_index == ss_arr_len - 1) {
        return (str_len, str);
    }

    return _loop_ss_arr_to_string(ss_arr_len, ss_arr, ss_index + 1, str_len, str);
}

// extract last character from short string
func conversion_extract_last_char_from_ss{
    bitwise_ptr: BitwiseBuiltin*, range_check_ptr, codec_char_size, codec_last_char_mask
}(ss: felt) -> (ss_rem: felt, char: felt) {
    with_attr error_message(
            "extract_last_char_from_ss: exceeding max short string value 2^248 - 1") {
        let (ss_masked) = bitwise_and(ss, SHORT_STRING_MAX_VALUE);
        assert ss - ss_masked = 0;
    }

    let (char) = bitwise_and(ss, codec_last_char_mask);
    let ss_rem = (ss - char) / codec_char_size;
    return (ss_rem, char);
}

// assert character encoding
func conversion_assert_char_encoding{range_check_ptr, codec_char_size}(char: felt) {
    with_attr error_message("assert_char_encoding: char is not a single character") {
        assert_lt(char, codec_char_size);
    }

    return ();
}
