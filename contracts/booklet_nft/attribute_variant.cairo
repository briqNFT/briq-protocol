%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin, SignatureBuiltin, BitwiseBuiltin
from starkware.cairo.common.math_cmp import is_le_felt
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.bitwise import bitwise_and
from starkware.starknet.common.syscalls import get_caller_address

from contracts.utilities.authorization import _onlyAdmin

from contracts.types import FTSpec, ShapeItem

from contracts.booklet_nft.token_uri import get_shape_contract_
from contracts.library_erc1155.balance import ERC1155_balance
from contracts.library_erc1155.transferability import ERC1155_transferability

from contracts.ecosystem.genesis_collection import GENESIS_COLLECTION

from contracts.ecosystem.to_attributes_registry import (
    _onlyAttributesRegistry
)

@contract_interface
namespace IShapeContract {
    func _shape() -> (shape_len: felt, shape: ShapeItem*, nfts_len: felt, nfts: felt*) {
    }

    func check_shape_numbers_(
        index: felt, shape_len: felt, shape: ShapeItem*, fts_len: felt, fts: FTSpec*, nfts_len: felt, nfts: felt*
    ) {
    }
}

@storage_var
func _wrapped_inside(booklet_token_id: felt) -> (set_token_id: felt) {
}


//###########
//###########

@external
func assign_attribute{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}(
    owner: felt,
    set_token_id: felt,
    attribute_id: felt,
    shape_len: felt, shape: ShapeItem*,
    fts_len: felt, fts: FTSpec*,
    nfts_len: felt, nfts: felt*,
) {
    alloc_locals;
    
    _onlyAttributesRegistry();

    // Check that the shape matches the passed data
    let (local addr) = get_shape_contract_(attribute_id);
    local pedersen_ptr: HashBuiltin* = pedersen_ptr;
    IShapeContract.library_call_check_shape_numbers_(
        addr, (attribute_id - GENESIS_COLLECTION) / 2**192, shape_len, shape, fts_len, fts, nfts_len, nfts
    );

    // Mark the booklet as wrapped inside the set.
    let (wrap) = _wrapped_inside.read(attribute_id);
    assert wrap = 0;
    _wrapped_inside.write(attribute_id, set_token_id);

    return ();
}

@external
func remove_attribute{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}(
    owner: felt,
    set_token_id: felt,
    attribute_id: felt,
) {
    _onlyAttributesRegistry();

    // Unmark the booklet as wrapped.
    let (wrap) = _wrapped_inside.read(attribute_id);
    assert wrap = set_token_id;
    _wrapped_inside.write(attribute_id, 0);

    return ();
}

@external
func safeTransferFrom_{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    sender: felt, recipient: felt, token_id: felt, value: felt, data_len: felt, data: felt*
) {
    let (wrap) = _wrapped_inside.read(token_id);
    assert wrap = 0;

    return ERC1155_transferability.safeTransferFrom_(sender, recipient, token_id, value, data_len, data);
}
