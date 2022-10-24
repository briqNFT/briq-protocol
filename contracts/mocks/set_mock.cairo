%lang starknet

from contracts.types import FTSpec

@external
func assemble_(
    owner: felt,
    token_id_hint: felt,
    name_len: felt, name: felt*,
    description_len: felt, description: felt*,
    fts_len: felt, fts: FTSpec*,
    nfts_len: felt, nfts: felt*,
    shape_len: felt, shape: ShapeItem*,
    attributes_len: felt, attributes: felt*,
) {
    return ();
}
