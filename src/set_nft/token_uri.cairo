// @view
fn tokenURI_(token_id: felt252) -> Array<felt252> {
    briq_protocol::utilities::token_uri::_getUrl(
        token_id,
        'https://api.briq.construction',
        '/v1/uri/set/',
        'starknet-mainnet/',
        '.json',
    )
}
