%lang starknet

from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.dict_access import DictAccess
from starkware.cairo.common.math import assert_le
from starkware.cairo.common.memcpy import memcpy
from starkware.cairo.common.squash_dict import squash_dict

// @dev Concatenates two arrays together
// @implicit range_check_ptr (felt)
// @param arr1_len (felt): The first array's length
// @param arr1 (felt* | struct*): The first array (can be a struct or a felt)
// @param arr2_len (felt): The second array's length
// @param arr2 (felt* | struct*): The second array (can be a struct or a felt)
// @param size (felt): The size of the struct
// @return concat_len (felt): The length of the concatenated array
// @return concat (felt*): The concatenated array (as a felt*, recast it for a struct*)
func concat_arr{range_check_ptr}(
    arr1_len: felt, arr1: felt*, arr2_len: felt, arr2: felt*, size: felt
) -> (concat_len: felt, concat: felt*) {
    alloc_locals;
    with_attr error_message("concat_arr: size must be greather or equal to 1") {
        assert_le(1, size);
    }
    let (local res: felt*) = alloc();
    memcpy(res, arr1, arr1_len * size);
    memcpy(res + arr1_len * size, arr2, arr2_len * size);
    return (arr1_len + arr2_len, res);
}

// @dev Concatenates two **felt** arrays together
// @implicit range_check_ptr (felt)
// @param arr1_len (felt): The first array's length
// @param arr1 (felt*): The first array
// @param arr2_len (felt): The second array's length
// @param arr2 (felt*): The second array
// @return concat_len (felt): The length of the concatenated array
// @return concat (felt*): The concatenated array
func concat_felt_arr{range_check_ptr}(arr1_len: felt, arr1: felt*, arr2_len: felt, arr2: felt*) -> (
    concat_len: felt, concat: felt*
) {
    return concat_arr(arr1_len, arr1, arr2_len, arr2, 1);
}

// @dev Inverts an array
// @implicit range_check_ptr (felt)
// @param arr_len (felt): The array's length
// @param arr (felt*): The array (can be a struct or a felt)
// @param size (felt): The struct size
// @return inv_arr_len (felt): The inverted array's length
// @return inv_arr (felt*): The inverted array
func invert_arr{range_check_ptr}(arr_len: felt, arr: felt*, size: felt) -> (
    inv_arr_len: felt, inv_arr: felt*
) {
    alloc_locals;
    with_attr error_message("invert_arr: size must be greather or equal to 1") {
        assert_le(1, size);
    }
    let (local inv_arr: felt*) = alloc();
    _loop_invert_arr(arr_len, arr, inv_arr, 0, size);
    return (arr_len, inv_arr);
}

// @dev Inverts a **felt** array
// @implicit range_check_ptr (felt)
// @param arr_len (felt): The array's length
// @param arr (felt*): The array (can be a struct or a felt)
// @param size (felt): The struct size
// @return inv_arr_len (felt): The inverted array's length
// @return inv_arr (felt*): The inverted array
func invert_felt_arr{range_check_ptr}(arr_len: felt, arr: felt*) -> (
    inv_arr_len: felt, inv_arr: felt*
) {
    return invert_arr(arr_len, arr, 1);
}

//
// Asserts
//

// @dev Asserts whether a **felt** array has no duplicate value
// @dev reverts if there is a duplicate value
// @implicit range_check_ptr (felt)
// @param arr_len (felt): The array's length
// @param arr (felt*): The array
func assert_felt_arr_unique{range_check_ptr}(arr_len: felt, arr: felt*) {
    alloc_locals;
    let (local dict_start: DictAccess*) = alloc();
    let (local squashed_dict: DictAccess*) = alloc();

    let (dict_end) = _build_dict(arr, arr_len, dict_start);

    with_attr error_message("assert_felt_arr_unique: array is not unique") {
        squash_dict(dict_start, dict_end, squashed_dict);
    }

    return ();
}

//
// Internals
//

func _build_dict(arr: felt*, n_steps: felt, dict: DictAccess*) -> (dict: DictAccess*) {
    if (n_steps == 0) {
        return (dict,);
    }

    assert dict.key = [arr];
    assert dict.prev_value = 0;
    assert dict.new_value = 1;

    return _build_dict(arr + 1, n_steps - 1, dict + DictAccess.SIZE);
}

func _loop_invert_arr{range_check_ptr}(
    arr_len: felt, arr: felt*, inv_arr: felt*, index: felt, size: felt
) {
    _sub_loop_invert_arr(arr_len, arr, inv_arr, size, index, size - 1);

    if (arr_len == 1) {
        return ();
    }

    return _loop_invert_arr(arr_len - 1, arr, inv_arr, index + 1, size);
}

func _sub_loop_invert_arr{range_check_ptr}(
    arr_len: felt, arr: felt*, inv_arr: felt*, size: felt, struct_index: felt, struct_offset: felt
) {
    tempvar in_id = (struct_index + 1) * size - 1 - struct_offset;
    tempvar out_id = arr_len * size - 1 - struct_offset;
    assert inv_arr[(struct_index + 1) * size - 1 - struct_offset] = arr[arr_len * size - 1 - struct_offset];

    if (struct_offset == 0) {
        return ();
    }

    return _sub_loop_invert_arr(arr_len, arr, inv_arr, size, struct_index, struct_offset - 1);
}
