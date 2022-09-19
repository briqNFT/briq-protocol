%lang starknet

from contracts.types import FTSpec

@external
func assemble_(
    owner: felt,
    token_id_hint: felt,
    fts_len: felt,
    fts: FTSpec*,
    nfts_len: felt,
    nfts: felt*,
    uri_len: felt,
    uri: felt*,
) {
    return ();
}
