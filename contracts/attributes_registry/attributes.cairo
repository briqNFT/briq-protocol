%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin, SignatureBuiltin, BitwiseBuiltin

from contracts.types import FTSpec, ShapeItem

from contract.attributes_registry.collections import (
    _collection_delegate_contract
)

@storage_var
func _cumulative_balance(owner: felt) -> (balance: felt) {
}



@contract_interface
namespace IDelegateContract {
    func assign_attribute(
        owner: felt,
        set_token_id: felt,
        attribute_id: felt,
        shape_len: felt, shape: ShapeItem*,
        fts_len: felt, fts: FTSpec*,
        nfts_len: felt, nfts: felt*,
    ) {}

    func check_shape_numbers_(
        shape_len: felt, shape: ShapeItem*, fts_len: felt, fts: FTSpec*, nfts_len: felt, nfts: felt*
    ) {
    }
}



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
    let (caller) = get_caller_address();
    let (set_addr) = getSetAddress_();
    // TODO: Set permissions on the collection (owner / set) ? 
    assert caller = set_addr;
    
    let collection_id = bitwse_and(attribute_id, COLLECTION_MASK)
    let delegate_contract = _collection_delegate_contract.read(collection_id);
    if (delegate_contract == 0) {
        // TODO
    } else {
        IDelegateContract.assign_attribute(
            delegate_contract,
            owner,
            set_token_id,
            attribute_id,
            shape_len, shape,
            fts_len, fts,
            nfts_len, nfts
        )
    }

    AttributeAssigned.emit();

    // Update the cumulative balance
    let (balance) = _cumulative_balance.read(set_token_id);
    with_attr error_message("Would overflow balance") {
        assert_lt_felt(balance, balance + 1);
    }
    _cumulative_balance.write(set_token_id, balance + 1);
}

@external
func remove_attribute{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}(
    owner: felt,
    set_token_id: felt,
    attribute_id: felt,
) {
    let (caller) = get_caller_address();
    let (set_addr) = getSetAddress_();
    assert caller = set_addr;

    let collection_id = bitwse_and(attribute_id, COLLECTION_MASK)
    let delegate_contract = _collection_delegate_contract.read(collection_id);
    if (delegate_contract == 0) {
        // TODO
    } else {
        IDelegateContract.remove_attribute(
            delegate_contract,
            owner,
            set_token_id,
            attribute_id,
            shape_len, shape,
            fts_len, fts,
            nfts_len, nfts
        )
    }

    AttributeRemoved.emit();

    // Update the cumulative balance
    let (balance) = _cumulative_balance.read(set_token_id);
    with_attr error_message("Insufficient balance") {
        assert_lt_felt(balance - 1, balance);
    }
    _cumulative_balance.write(set_token_id, balance - 1);
}

@view
func has_attribute{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}(
    set_token_id: felt, attribute_id: felt
) {
}

@view
func total_balance{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}(
    set_token_id: felt, attribute_id: felt
) -> total_balance: felt {
}

// Maybe?
@view
func token_uri{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}(
    set_token_id: felt, attribute_id: felt
) {
}
