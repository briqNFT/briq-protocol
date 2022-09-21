%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin, SignatureBuiltin
from starkware.cairo.common.math import assert_lt_felt
from starkware.starknet.common.syscalls import get_caller_address

from contracts.attributes_registry.token_uri import _shape_contract

from contracts.ecosystem.to_box import _box_address


@storage_var
func _collection(collection_id: felt) -> (parameters: felt) {
}

// Only needed if there is no delegate contract
@storage_var
func _collection_admin(collection_id: felt) -> (admin: felt) {
}

// Set to 0 if there is no delegate contract.
@storage_var
func _collection_delegate_contract(collection_id: felt) -> (contract_address: felt) {
}

@external
func create_collection_{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    admin: felt, collection_id: felt
) {
    // TODO: event

    return ();
}
