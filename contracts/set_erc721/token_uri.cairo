%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin, SignatureBuiltin, BitwiseBuiltin
from starkware.starknet.common.syscalls import get_caller_address
from starkware.cairo.common.math import (
    assert_nn_le,
    assert_lt,
    assert_le,
    assert_not_zero,
    assert_lt_felt,
    unsigned_div_rem,
    assert_not_equal,
)
from starkware.cairo.common.registers import get_fp_and_pc
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.bool import FALSE

from starkware.cairo.common.bitwise import bitwise_and

from starkware.cairo.common.registers import get_label_location

from contracts.library_erc721.balance import _owner

from contracts.utilities.authorization import _onlyAdmin

from contracts.ecosystem.to_briq import _briq_address

from contracts.vendor.caistring.str import Str, str_concat


@contract_interface
namespace IBriqContract {
    func balanceOfMaterial_(owner: felt, material: felt) -> (balance: felt) {
    }
}

//###########
//###########
//###########
// Storage variables.

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

//###########
//###########
//###########
// Events

// # ERC1155 compatibility
@event
func URI(value__len: felt, value_: felt*, id_: felt) {
}

//###########
//###########
//###########
// Public functions - no authentication required

func _fetchExtraUri{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, bitwise_ptr: BitwiseBuiltin*, range_check_ptr
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

@view
func tokenURI_{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, bitwise_ptr: BitwiseBuiltin*, range_check_ptr
}(token_id: felt) -> (uri_len: felt, uri: felt*) {
    // OZ ∆: don't check for non-existent token.
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
    // return (0)
}

//###########
//###########
//###########
// Auth functions

func _setExtraTokenURI{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, bitwise_ptr: BitwiseBuiltin*, range_check_ptr
}(token_id: felt, max: felt, index: felt, uri: felt*) {
    assert_lt_felt(uri[0], 2 ** 249);
    if (max == index) {
        _token_uri_extra.write(token_id, index, uri[0] * 4);
        return ();
    }
    _token_uri_extra.write(token_id, index, uri[0] * 4 + 1);
    return _setExtraTokenURI(token_id, max, index + 1, uri + 1);
}

func _setTokenURI{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, bitwise_ptr: BitwiseBuiltin*, range_check_ptr
}(may_use_special_token_mode: felt, token_id: felt, uri_len: felt, uri: felt*) {
    assert_not_zero(uri_len);
    assert_lt_felt(uri[0], 2 ** 249);
    assert_lt_felt(may_use_special_token_mode, 2);

    // This is 0 or 1
    if (uri_len * may_use_special_token_mode == 2) {
        let (rem) = bitwise_and(uri[1], 2 ** 59 - 1);
        if (uri[1] == rem) {
            // The rest has already been written in the token-id
            // Flag it with both special bits for continuation and 'part of token_id'.
            _token_uri.write(token_id, uri[0] * 4 + 3);
            return ();
        }
        // Write the first URI with the special continuation LSB
        _token_uri.write(token_id, uri[0] * 4 + 1);
        _setExtraTokenURI(token_id, uri_len - 2, 0, uri + 1);
        // event_uri.emit(token_id, uri_len, uri)
    } else {
        if (uri_len == 1) {
            // Just write the URI normally.
            _token_uri.write(token_id, uri[0] * 4);
            return ();
        }
        // Write the first URI with the special continuation LSB
        _token_uri.write(token_id, uri[0] * 4 + 1);
        _setExtraTokenURI(token_id, uri_len - 2, 0, uri + 1);
        // event_uri.emit(token_id, uri_len, uri)
    }
    return ();
}

// # Testing only
@external
func setTokenURI_{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, bitwise_ptr: BitwiseBuiltin*, range_check_ptr
}(token_id: felt, uri_len: felt, uri: felt*) {
    alloc_locals;
    _onlyAdmin();

    // TODO: is this useless?
    let (owner) = _owner.read(token_id);
    assert_not_zero(owner);

    _setTokenURI(FALSE, token_id, uri_len, uri);

    URI.emit(uri_len, uri, token_id);

    return ();
}

@view
func is_realms_set_{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    token_id: felt
) -> (is_realms: felt) {
    let (address) = _briq_address.read();
    let (nb_normal_briqs) = IBriqContract.balanceOfMaterial_(address, token_id, 1);
    if (nb_normal_briqs != 0) {
        return (0,);
    }
    let (nb_realms_briqs) = IBriqContract.balanceOfMaterial_(address, token_id, 2);
    if (nb_realms_briqs == 0) {
        return (0,);
    }
    return (1,);
}

@view
func tokenURIData_{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, bitwise_ptr: BitwiseBuiltin*, range_check_ptr
}(token_id: felt) -> (uri_len: felt, uri: felt*) {
    alloc_locals;
    let (data_url_len, data_url) = tokenURI_(token_id);

    let (data_address) = get_label_location(data_uri_start);
    tempvar uri = Str(2, cast(data_address, felt*));
    tempvar data = Str(data_url_len, data_url);

    let (res) = str_concat(uri, data);

    let (data_address) = get_label_location(data_uri_middle);
    tempvar uri = Str(2, cast(data_address, felt*));
    let (local res: Str) = str_concat(res, uri);
    let (is_realms) = is_realms_set_(token_id);

    if (is_realms == 0) {
        let (data_address) = get_label_location(data_uri_end_no);
        tempvar uri = Str(1, cast(data_address, felt*));
        let (result_) = str_concat(res, uri);
        return (result_.arr_len, result_.arr);
    }

    let (data_address) = get_label_location(data_uri_end_yes);
    tempvar uri = Str(1, cast(data_address, felt*));
    let (result_) = str_concat(res, uri);
    return (result_.arr_len, result_.arr);

    data_uri_start:
    dw 'data:application/json,';
    dw '{ "metadata": "';

    data_uri_middle:
    dw '", "attributes": [{';
    dw '"trait_type": "Realms", ';

    data_uri_end_yes:
    dw '"value": "yes"}]}';

    data_uri_end_no:
    dw '"value": "no"}]}';
}
