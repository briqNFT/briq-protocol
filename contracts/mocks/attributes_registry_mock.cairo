%lang starknet

from contracts.types import FTSpec, ShapeItem

@view
func total_balance(owner: felt) -> (balance: felt) {
    return (0,);
}

@external
func assign_attributes(
    owner: felt,
    set_token_id: felt,
    attributes_len: felt, attributes: felt*,
    shape_len: felt, shape: ShapeItem*,
    fts_len: felt, fts: FTSpec*,
    nfts_len: felt, nfts: felt*
) {
    return ();
}

@external
func remove_attributes(
    owner: felt,
    set_token_id: felt,
    attributes_len: felt, attributes: felt*,
) {
    return ();
}