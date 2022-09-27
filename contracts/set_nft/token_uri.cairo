%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin, SignatureBuiltin, BitwiseBuiltin

from contracts.utilities.token_uri import TokenURIHelpers

data_uri_start:
dw 'https://api.briq.construction';
dw '/v1/uri/set/';
dw 'starknet-testnet/';
dw '.json';

@view
func tokenURI_{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    token_id: felt
) -> (uri_len: felt, uri: felt*) {
    return TokenURIHelpers._getUrl(token_id, data_uri_start);
}
