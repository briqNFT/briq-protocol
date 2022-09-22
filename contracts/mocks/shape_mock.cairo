%lang starknet

from contracts.types import ShapeItem, FTSpec

@external
func check_shape_numbers_(
    index: felt, shape_len: felt, shape: ShapeItem*, fts_len: felt, fts: FTSpec*, nfts_len: felt, nfts: felt*
) {
    return ();
}
