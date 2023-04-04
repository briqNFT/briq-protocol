%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin, SignatureBuiltin, BitwiseBuiltin
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.registers import get_label_location
from starkware.cairo.common.math import split_int
from starkware.cairo.common.memcpy import memcpy

from contracts.vendor.cairopen.string.ASCII import StringCodec

from starkware.cairo.common.uint256 import Uint256
from starkware.cairo.common.bitwise import bitwise_and

from contracts.utilities.Uint256_felt_conv import _uint_to_felt, _felt_to_uint


@event
func URI(_value_len: felt, _value: felt*, _id: Uint256) {
}

namespace TokenURIHelpers {

    func _onUriChange{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        token_id: felt, new_uri_len: felt, new_uri: felt*
    ) {
        alloc_locals;
        let (tk) = _felt_to_uint(token_id);
        URI.emit(new_uri_len, new_uri, tk);
        return ();
    }

    func _getUrl{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        token_id: felt, label: codeoffset
    ) -> (uri_len: felt, uri: felt*) {
        alloc_locals;

        let (data_address) = get_label_location(label);
        let (local uri_out: felt*) = alloc();
        assert uri_out[0] = data_address[0];
        assert uri_out[1] = data_address[1];
        // TODO: change on a per-network basis?
        assert uri_out[2] = data_address[2];

        // Parse the token ID as a string.
        let (outout: felt*) = alloc();
        split_int(token_id, 4, 10**20, 2**80, outout);
        let (sum) = add_number(4, 3, outout, uri_out, 1);
        assert uri_out[sum] = data_address[3];

        return (sum + 1, uri_out);
    }

    func padl{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        n: felt, data: felt*
    ) -> felt {
        if (n == 0) {
            return (20);
        }
        assert data[0] = '0';
        return padl(n - 1, data + 1);
    }


    func add_number{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        i: felt, sum: felt, data_in: felt*, data_out: felt*, leading_zero: felt,
    ) -> (sum: felt) {
        alloc_locals;
        if (i == 0) {
            return (sum,);
        }
        let (token_id_ascii) = StringCodec.felt_to_string(data_in[i - 1]);
        if (data_in[i - 1] == 0 and leading_zero == 1) {
            return add_number(i - 1, sum, data_in, data_out, 1);
        }
        let toto = (20 - token_id_ascii.len) * (1 - leading_zero);
        padl(toto, data_out + sum);
        memcpy(data_out + sum + toto, token_id_ascii.data, token_id_ascii.len);
        return add_number(i - 1, sum + toto + token_id_ascii.len, data_in, data_out, 0);
    }
}