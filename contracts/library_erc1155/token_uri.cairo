%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin, SignatureBuiltin, BitwiseBuiltin
from starkware.cairo.common.uint256 import Uint256
from starkware.cairo.common.bitwise import bitwise_and
from starkware.cairo.common.alloc import alloc


@event
func URI(_value_len: felt, _value: felt*, _id: Uint256) {
}

// To save on gas costs, the LSB of the token_uri can be 1 to indicate extra data is present. A 0 indicates no extra data.
// Further, the next LSB stores whether the token URI is partly written in the token_id or not.
// Because felts are 251 bits, that means we can store at most 249 bits of information.
// This is fine because ASCII strings are 31 characters, or 248 bits.
@storage_var
func _token_uri(token_id: felt) -> (token_uri: felt) {
}

// Likewise, the LSB indicates whether the data continues or not.
@storage_var
func _token_uri_extra(token_id: felt, index: felt) -> (uri_data: felt) {
}

namespace ERC1155_token_uri {
    @view
    func uri_{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, bitwise_ptr: BitwiseBuiltin*, range_check_ptr}(token_id: felt) -> (
        uri_len: felt, uri: felt*
    ) {
        let (uri_len, uri) = tokenURI_(token_id);
        return (uri_len, uri);
    }

    func _fetchExtraUri{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        bitwise_ptr: BitwiseBuiltin*,
        range_check_ptr,
    }(token_id: felt, index: felt, res: felt*) -> (nb: felt) {
        let (tok) = _token_uri_extra.read(token_id, index);
        let (extra) = bitwise_and(tok, 1);
        if (extra == 0) {
            tempvar calc = tok / 4;
            res[0] = calc;
            return (index,);
        }
        tempvar calc = (tok - 1) / 4;
        res[0] = calc;
        return _fetchExtraUri(token_id, index + 1, res + 1);
    }

    func tokenURI_{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        bitwise_ptr: BitwiseBuiltin*,
        range_check_ptr,
    }(token_id: felt) -> (uri_len: felt, uri: felt*) {
        alloc_locals;
        let (tok) = _token_uri.read(token_id);
        let (extra) = bitwise_and(tok, 3);  // two LSBs
        let (local res: felt*) = alloc();
        if (extra == 0) {
            tempvar calc = tok / 4;
            res[0] = calc;
            return (1, res);
        } else {
            // Special token_id mode.
            if (extra == 3) {
                tempvar calc = (tok - 3) / 4;
                res[0] = calc;
                let (toktok) = bitwise_and(token_id, 2 ** 59 - 1);
                res[1] = toktok;
                return (2, res);
            }
            tempvar calc = (tok - 1) / 4;
            res[0] = calc;
            let (nb_items) = _fetchExtraUri(token_id, 0, res + 1);
            return (nb_items + 2, res);
        }
    }
}
