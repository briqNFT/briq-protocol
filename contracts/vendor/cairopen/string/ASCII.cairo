%lang starknet

from starkware.cairo.common.cairo_builtins import BitwiseBuiltin, HashBuiltin

from cairopen.string.string import String
from cairopen.string.libs.storage import (
    storage_read,
    storage_write,
    storage_write_from_char_arr,
    storage_delete,
)
from cairopen.string.libs.conversion import (
    conversion_felt_to_string,
    conversion_ss_to_string,
    conversion_ss_arr_to_string,
    conversion_extract_last_char_from_ss,
    conversion_assert_char_encoding,
)

namespace StringCodec {
    //
    // Constants
    //

    // @dev Characters encoded in ASCII so 8 bits
    const CHAR_SIZE = 256;

    // @dev Mask to retreive the last character (= 0b00...0011111111 = 0x00...00ff)
    const LAST_CHAR_MASK = CHAR_SIZE - 1;

    // @dev add 48 to a number in range [0, 9] for ASCII character code
    const NUMERICAL_OFFSET = 48;

    //
    // Storage
    //

    // @dev Reads a String from storage based on its ID
    // @implicit syscall_ptr (felt*)
    // @implicit bitwise_ptr (BitwiseBuiltin*)
    // @implicit pedersen_ptr (HashBuiltin*)
    // @implicit range_check_ptr (felt)
    // @param str_id (felt): The ID of the String to read
    // @return str (String): The String
    func read{
        syscall_ptr: felt*,
        bitwise_ptr: BitwiseBuiltin*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr,
    }(str_id: felt) -> (str: String) {
        let codec_char_size = CHAR_SIZE;
        let codec_last_char_mask = LAST_CHAR_MASK;
        with codec_char_size, codec_last_char_mask {
            let (str) = storage_read(str_id);
        }
        return (str,);
    }

    // @dev Writes a String in storage based on its ID
    // @implicit syscall_ptr (felt*)
    // @implicit pedersen_ptr (HashBuiltin*)
    // @implicit range_check_ptr (felt)
    // @param str_id (felt): The ID of the String to write
    // @param str (String): The String
    func write{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        str_id: felt, str: String
    ) {
        let codec_char_size = CHAR_SIZE;
        with codec_char_size {
            storage_write(str_id, str);
        }
        return ();
    }

    // @dev Writes a String from a char array in storage based on its ID
    // @implicit syscall_ptr (felt*)
    // @implicit pedersen_ptr (HashBuiltin*)
    // @implicit range_check_ptr (felt)
    // @param str_id (felt): The ID of the String to store
    // @param str_len (felt): The length of the String
    // @param str_data (felt*): The String itself (in char array format)
    func write_from_char_arr{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        str_id: felt, str_len: felt, str_data: felt*
    ) {
        let codec_char_size = CHAR_SIZE;
        with codec_char_size {
            storage_write_from_char_arr(str_id, str_len, str_data);
        }
        return ();
    }

    // @dev Deletes a String in storage based on its ID
    // @implicit syscall_ptr (felt*)
    // @implicit pedersen_ptr (HashBuiltin*)
    // @implicit range_check_ptr (felt)
    // @param str_id (felt): The ID of the String to delete
    func delete{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(str_id: felt) {
        return storage_delete(str_id);
    }

    //
    // Conversion
    //

    // @dev Converts a felt to its ASCII String value
    // @implicit range_check_ptr (felt)
    // @param elem (felt): The felt value to convert
    // @return str (String): The String
    func felt_to_string{range_check_ptr}(elem: felt) -> (str: String) {
        let codec_numerical_offset = NUMERICAL_OFFSET;
        with codec_numerical_offset {
            let (str) = conversion_felt_to_string(elem);
        }
        return (str,);
    }

    // @dev Converts a short string into a String
    // @implicit bitwise_ptr (BitwiseBuiltin*)
    // @implicit range_check_ptr (felt)
    // @param ss (felt): The short String to convert
    // @return str (String): The String
    func ss_to_string{bitwise_ptr: BitwiseBuiltin*, range_check_ptr}(ss: felt) -> (str: String) {
        let codec_char_size = CHAR_SIZE;
        let codec_last_char_mask = LAST_CHAR_MASK;
        with codec_char_size, codec_last_char_mask {
            let (str) = conversion_ss_to_string(ss);
        }
        return (str,);
    }

    // @dev Converts an array of short strings into a single String
    // @implicit bitwise_ptr (BitwiseBuiltin*)
    // @implicit range_check_ptr (felt)
    // @param ss_arr_len (felt): The length of array
    // @param ss_arr (felt*): The array of short strings to convert
    // @return str (String): The String
    func ss_arr_to_string{bitwise_ptr: BitwiseBuiltin*, range_check_ptr}(
        ss_arr_len: felt, ss_arr: felt*
    ) -> (str: String) {
        let codec_char_size = CHAR_SIZE;
        let codec_last_char_mask = LAST_CHAR_MASK;
        with codec_char_size, codec_last_char_mask {
            let (str) = conversion_ss_arr_to_string(ss_arr_len, ss_arr);
        }
        return (str,);
    }

    // @dev Extracts the last character from a short string and returns the characters before as a short string
    // @dev Manages felt up to 2**248 - 1 (instead of unsigned_div_rem which is limited by rc_bound)
    // @dev _On the down side it requires BitwiseBuiltin for the whole call chain_
    // @implicit bitwise_ptr (BitwiseBuiltin*)
    // @implicit range_check_ptr (felt)
    // @param ss (felt): The short string
    // @return ss_rem (felt): The remaining short string
    // @return char (felt): The last character
    func extract_last_char_from_ss{bitwise_ptr: BitwiseBuiltin*, range_check_ptr}(ss: felt) -> (
        ss_rem: felt, char: felt
    ) {
        let codec_char_size = CHAR_SIZE;
        let codec_last_char_mask = LAST_CHAR_MASK;
        with codec_char_size, codec_last_char_mask {
            let (ss_rem, char) = conversion_extract_last_char_from_ss(ss);
        }
        return (ss_rem, char);
    }

    // @dev Checks whether a felt **could** be a character (< CHAR_SIZE)
    // @implicit range_check_ptr (felt)
    // @param char (felt): The character to check
    func assert_char_encoding{range_check_ptr}(char: felt) {
        let codec_char_size = CHAR_SIZE;
        with codec_char_size {
            conversion_assert_char_encoding(char);
        }
        return ();
    }
}
