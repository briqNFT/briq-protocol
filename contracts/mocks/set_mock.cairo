%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from contracts.types import FTSpec, ShapeItem

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

// Very basic implem

@storage_var
func __balance(token_id: felt) -> (owner: felt) {
}

@external
func transferFrom_{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    sender: felt,
    receiver: felt,
    token_id: felt,
) {
    alloc_locals;

    let (owner) = __balance.read(token_id);
    assert sender = owner;
    __balance.write(token_id, receiver);
    return ();
}

@view
func ownerOf_{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    token_id: felt
) -> (owner: felt) {
    let (owner) = __balance.read(token_id);
    return (owner,);
}
