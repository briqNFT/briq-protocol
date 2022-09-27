%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin, SignatureBuiltin, BitwiseBuiltin
from starkware.starknet.common.syscalls import get_caller_address
from starkware.cairo.common.bitwise import bitwise_and
from starkware.cairo.common.uint256 import Uint256
from starkware.cairo.common.math import assert_lt_felt
from contracts.utilities.Uint256_felt_conv import _felt_to_uint

from contracts.types import FTSpec, ShapeItem

from contracts.attributes_registry.collections import (
    _get_admin_or_contract,
    _get_collection_id,
)

from contracts.library_erc1155.balance import ERC1155_balance
from contracts.library_erc1155.transferability import ERC1155_transferability

from contracts.ecosystem.to_set import (
    getSetAddress_,
    setSetAddress_,
)

@storage_var
func _cumulative_balance(owner: felt) -> (balance: felt) {
}

@event
func AttributeAssigned(set_token_id: Uint256, attribute_id: felt) {
}

@event
func AttributeRemoved(set_token_id: Uint256, attribute_id: felt) {
}

func _EmitAssigned{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, bitwise_ptr: BitwiseBuiltin*, range_check_ptr}(
    set_token_id: felt, attribute_id: felt
) {
    alloc_locals;
    let (tk) = _felt_to_uint(set_token_id);
    AttributeAssigned.emit(tk, attribute_id);
    return ();
}

func _EmitRemoved{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, bitwise_ptr: BitwiseBuiltin*, range_check_ptr}(
    set_token_id: felt, attribute_id: felt
) {
    alloc_locals;
    let (tk) = _felt_to_uint(set_token_id);
    AttributeRemoved.emit(tk, attribute_id);
    return ();
}


@contract_interface
namespace IDelegateContract {
    func assign_attribute(
        owner: felt,
        set_token_id: felt,
        attribute_id: felt,
        shape_len: felt, shape: ShapeItem*,
        fts_len: felt, fts: FTSpec*,
        nfts_len: felt, nfts: felt*,) {
    }

    func remove_attribute(
        owner: felt,
        set_token_id: felt,
        attribute_id: felt,) {
    }

    func balanceOf_(
        owner: felt,
        attribute_id: felt) -> (balance: felt) {
    }
}


@external
func assign_attributes{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, bitwise_ptr: BitwiseBuiltin*, range_check_ptr
}(
    set_owner: felt,
    set_token_id: felt,
    attributes_len: felt, attributes: felt*,
    shape_len: felt, shape: ShapeItem*,
    fts_len: felt, fts: FTSpec*,
    nfts_len: felt, nfts: felt*,
) {
    if (attributes_len == 0) {
        return ();
    }
    assign_attribute(set_owner, set_token_id, attributes[0], shape_len, shape, fts_len, fts, nfts_len, nfts);
    return assign_attributes(set_owner, set_token_id, attributes_len - 1, attributes + 1, shape_len, shape, fts_len, fts, nfts_len, nfts);
}

@external
func assign_attribute{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, bitwise_ptr: BitwiseBuiltin*, range_check_ptr
}(
    set_owner: felt,
    set_token_id: felt,
    attribute_id: felt,
    shape_len: felt, shape: ShapeItem*,
    fts_len: felt, fts: FTSpec*,
    nfts_len: felt, nfts: felt*,
) {
    alloc_locals;
    let (caller) = get_caller_address();
    let (set_addr) = getSetAddress_();
    // TODO: Set permissions on the collection (owner / set) ? 
    assert caller = set_addr;
    
    let (admin, delegate_contract) = _get_admin_or_contract(_get_collection_id(attribute_id));
    if (delegate_contract == 0) {
        ERC1155_transferability._transfer_burnable(0, set_token_id, attribute_id, 1);
        tempvar syscall_ptr = syscall_ptr;
        tempvar pedersen_ptr = pedersen_ptr;
        tempvar range_check_ptr = range_check_ptr;
    } else {
        IDelegateContract.assign_attribute(
            delegate_contract,
            set_owner,
            set_token_id,
            attribute_id,
            shape_len, shape,
            fts_len, fts,
            nfts_len, nfts
        );
        tempvar syscall_ptr = syscall_ptr;
        tempvar pedersen_ptr = pedersen_ptr;
        tempvar range_check_ptr = range_check_ptr;
    }

    _EmitAssigned(set_token_id, attribute_id);

    // Update the cumulative balance
    let (balance) = _cumulative_balance.read(set_token_id);
    with_attr error_message("Would overflow balance") {
        assert_lt_felt(balance, balance + 1);
    }
    _cumulative_balance.write(set_token_id, balance + 1);
    return ();
}


@external
func remove_attributes{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, bitwise_ptr: BitwiseBuiltin*, range_check_ptr
}(
    set_owner: felt,
    set_token_id: felt,
    attributes_len: felt, attributes: felt*
) {
    if (attributes_len == 0) {
        return ();
    }
    remove_attribute(set_owner, set_token_id, attributes[0]);
    return remove_attributes(set_owner, set_token_id, attributes_len - 1, attributes + 1);
}


@external
func remove_attribute{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, bitwise_ptr: BitwiseBuiltin*, range_check_ptr
}(
    set_owner: felt,
    set_token_id: felt,
    attribute_id: felt,
) {
    alloc_locals;
    let (caller) = get_caller_address();
    let (set_addr) = getSetAddress_();
    assert caller = set_addr;

    let (admin, delegate_contract) = _get_admin_or_contract(_get_collection_id(attribute_id));
    if (delegate_contract == 0) {
        ERC1155_transferability._transfer_burnable(set_token_id, 0, attribute_id, 1);
        tempvar syscall_ptr = syscall_ptr;
        tempvar pedersen_ptr = pedersen_ptr;
        tempvar range_check_ptr = range_check_ptr;
    } else {
        IDelegateContract.remove_attribute(
            delegate_contract,
            set_owner,
            set_token_id,
            attribute_id,
        );
        tempvar syscall_ptr = syscall_ptr;
        tempvar pedersen_ptr = pedersen_ptr;
        tempvar range_check_ptr = range_check_ptr;
    }

    _EmitRemoved(set_token_id, attribute_id);

    // Update the cumulative balance
    let (balance) = _cumulative_balance.read(set_token_id);
    with_attr error_message("Insufficient balance") {
        assert_lt_felt(balance - 1, balance);
    }
    _cumulative_balance.write(set_token_id, balance - 1);
    return ();
}

@view
func has_attribute{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, bitwise_ptr: BitwiseBuiltin*, range_check_ptr
}(
    set_token_id: felt, attribute_id: felt
) -> (has_attribute: felt) {
    let (_, delegate_contract) = _get_admin_or_contract(_get_collection_id(attribute_id));
    if (delegate_contract == 0) {
        let (balance) = ERC1155_balance.balanceOf_(set_token_id, attribute_id);
        return (balance,);
    } else {
        let (balance) = IDelegateContract.balanceOf_(delegate_contract, set_token_id, attribute_id);
        return (balance,);
    }
}

@view
func total_balance{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, bitwise_ptr: BitwiseBuiltin*, range_check_ptr
}(
    owner: felt
) -> (total_balance: felt) {
    let (balance) = _cumulative_balance.read(owner);
    return (balance,);
}

// Maybe?
@view
func token_uri{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}(
    set_token_id: felt, attribute_id: felt
) {
    return ();
}
