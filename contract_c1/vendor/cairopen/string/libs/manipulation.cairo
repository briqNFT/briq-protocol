%lang starknet

from starkware.cairo.common.cairo_builtins import BitwiseBuiltin
from starkware.cairo.common.alloc import alloc

from cairopen.math.array import concat_felt_arr
from cairopen.string.string import String

// concat
func manipulation_concat{range_check_ptr}(str1: String, str2: String) -> (str: String) {
    let (concat_len, concat) = concat_felt_arr(str1.len, str1.data, str2.len, str2.data);
    return (String(concat_len, concat),);
}

// append character
func manipulation_append_char{range_check_ptr}(base: String, char: felt) -> (str: String) {
    assert base.data[base.len] = char;

    return (String(base.len + 1, base.data),);
}

// path join
func manipulation_path_join{range_check_ptr}(path1: String, path2: String) -> (path: String) {
    if (path1.data[path1.len - 1] == '/') {
        let (path) = manipulation_concat(path1, path2);
        return (path,);
    }

    let (slash_base) = manipulation_append_char(path1, '/');
    let (path) = manipulation_concat(slash_base, path2);
    return (path,);
}
