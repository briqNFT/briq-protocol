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

    // Transfer the booklet to the set.
    // The owner of the set must also be the owner of the booklet.
    ERC1155_transferability._transfer(owner, set_token_id, attribute_id, 1);

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

    // Give the booklet back to the original set owner.
    ERC1155_transferability._transfer(set_token_id, owner, attribute_id, 1);

    return ();
}
