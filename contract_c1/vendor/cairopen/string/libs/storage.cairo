%lang starknet

from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.cairo_builtins import BitwiseBuiltin, HashBuiltin
from starkware.cairo.common.math import unsigned_div_rem, assert_le
from starkware.cairo.common.pow import pow

from cairopen.string.string import String
from cairopen.string.libs.conversion import conversion_extract_last_char_from_ss
from cairopen.string.constants import SHORT_STRING_MAX_LEN, STRING_MAX_LEN

@storage_var
func strings_data(str_id: felt, short_string_index: felt) -> (short_string: felt) {
}

@storage_var
func strings_len(str_id: felt) -> (length: felt) {
}

// read
func storage_read{
    syscall_ptr: felt*,
    bitwise_ptr: BitwiseBuiltin*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr,
    codec_char_size,
    codec_last_char_mask,
}(str_id: felt) -> (str: String) {
    alloc_locals;
    let (str) = alloc();

    let (str_len) = strings_len.read(str_id);

    if (str_len == 0) {
        return (String(str_len, str),);
    }

    let (full_ss_len, rem_char_len) = unsigned_div_rem(str_len, SHORT_STRING_MAX_LEN);

    // Initiate loop with # of short strings and the last short string length
    _loop_get_ss(str_id, full_ss_len, rem_char_len, str);
    return (String(str_len, str),);
}

func _loop_get_ss{
    syscall_ptr: felt*,
    bitwise_ptr: BitwiseBuiltin*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr,
    codec_char_size,
    codec_last_char_mask,
}(str_id: felt, ss_index: felt, ss_len: felt, str: felt*) {
    let (ss_felt) = strings_data.read(str_id, ss_index);
    // Get and separate each character in the short string
    _loop_get_ss_char(ss_felt, ss_index, ss_len, str);

    if (ss_index == 0) {
        return ();
    }
    // Go to the previous short string
    _loop_get_ss(str_id, ss_index - 1, SHORT_STRING_MAX_LEN, str);
    return ();
}

func _loop_get_ss_char{
    syscall_ptr: felt*,
    bitwise_ptr: BitwiseBuiltin*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr,
    codec_char_size,
    codec_last_char_mask,
}(ss_felt: felt, ss_position: felt, char_index: felt, str: felt*) {
    // Must be checked at beginning of function here for the case where str_len = x * SHORT_STRING_MAX_LEN
    if (char_index == 0) {
        return ();
    }

    // Extract last character from short string
    let (ss_rem, char) = conversion_extract_last_char_from_ss(ss_felt);

    // Store the character in the correct position, i.e. SHORT_STRING_INDEX * SHORT_STRING_MAX_LEN + INDEX_IN_SHORT_STRING
    assert str[ss_position * SHORT_STRING_MAX_LEN + char_index - 1] = char;
    _loop_get_ss_char(ss_rem, ss_position, char_index - 1, str);
    return ();
}

// write
func storage_write{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr, codec_char_size
}(str_id: felt, str: String) {
    alloc_locals;
    with_attr error_message("write: exceeding max String length 2^15") {
        assert_le(str.len, STRING_MAX_LEN);
    }
    strings_len.write(str_id, str.len);

    if (str.len == 0) {
        return ();
    }

    let (full_ss_len, rem_char_len) = unsigned_div_rem(str.len, SHORT_STRING_MAX_LEN);

    // Initiate loop with # of short strings and the last short string length
    _loop_set_ss(str_id, full_ss_len, rem_char_len, str.data);
    return ();
}

func _loop_set_ss{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr, codec_char_size}(
    str_id: felt, ss_index: felt, ss_len: felt, str: felt*
) {
    // Accumulate all characters in a felt and write it
    _loop_set_ss_char(str_id, 0, ss_index, ss_len, ss_len, str);

    if (ss_index == 0) {
        return ();
    }
    // Go to the previous short string
    _loop_set_ss(str_id, ss_index - 1, SHORT_STRING_MAX_LEN, str);
    return ();
}

func _loop_set_ss_char{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr, codec_char_size
}(str_id: felt, ss_felt_acc: felt, ss_position: felt, ss_len: felt, char_index: felt, str: felt*) {
    if (char_index == 0) {
        strings_data.write(str_id, ss_position, ss_felt_acc);
        return ();
    }

    let (char_offset) = pow(codec_char_size, ss_len - char_index);
    let ss_felt = ss_felt_acc + str[ss_position * SHORT_STRING_MAX_LEN + char_index - 1] * char_offset;
    _loop_set_ss_char(str_id, ss_felt, ss_position, ss_len, char_index - 1, str);
    return ();
}

// write from character array
func storage_write_from_char_arr{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr, codec_char_size
}(str_id: felt, str_len: felt, str_data: felt*) {
    storage_write(str_id, String(str_len, str_data));
    return ();
}

// delete
func storage_delete{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(str_id: felt) {
    alloc_locals;
    let (str_len) = strings_len.read(str_id);

    if (str_len == 0) {
        return ();
    }

    strings_len.write(str_id, 0);

    let (ss_cells, _) = unsigned_div_rem(str_len, SHORT_STRING_MAX_LEN);
    _loop_delete(str_id, ss_cells);
    return ();
}

func _loop_delete{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    str_id: felt, ss_index: felt
) {
    strings_data.write(str_id, ss_index, 0);

    if (ss_index == 0) {
        return ();
    }

    _loop_delete(str_id, ss_index - 1);
    return ();
}
