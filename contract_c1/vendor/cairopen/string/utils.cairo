%lang starknet

from cairopen.string.string import String
from cairopen.string.libs.manipulation import (
    manipulation_concat,
    manipulation_append_char,
    manipulation_path_join,
)

namespace StringUtil {
    // @dev Concatenates two Strings together
    // @implicit range_check_ptr (felt)
    // @param str1 (String): The first String
    // @param str2 (String): The second String
    // @return str (String): The appended String
    func concat{range_check_ptr}(str1: String, str2: String) -> (str: String) {
        return manipulation_concat(str1, str2);
    }

    // @dev Appends a **single** char as a short string to a String
    // @implicit range_check_ptr (felt)
    // @param base (String): The base String
    // @param char (felt): The character to append
    // @return str (String): The appended String
    func append_char{range_check_ptr}(base: String, char: felt) -> (str: String) {
        return manipulation_append_char(base, char);
    }

    // @dev Joins to Strings together and adding a '/' in between if needed
    // @implicit range_check_ptr (felt)
    // @param path1 (String): The path start
    // @param path2 (String): The path end
    // @return path (String): The full path
    func path_join{range_check_ptr}(path1: String, path2: String) -> (path: String) {
        return manipulation_path_join(path1, path2);
    }
}
