%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin, SignatureBuiltin, BitwiseBuiltin
from starkware.cairo.common.bitwise import bitwise_and
from starkware.cairo.common.math import assert_not_zero
from contracts.utilities.authorization import _only, _onlyAdmin
from contracts.library_erc1155.balance import ERC1155_balance

const RESERVED_BITS = 2**0;
const CONTRACT_BIT = 2**1;

const COLLECTION_ID_MASK = 2**192 - 1;

@storage_var
func _collection_data(collection_id: felt) -> (parameters__admin_or_contract: (felt, felt)) {
}



@external
func create_collection_{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    collection_id: felt, params: felt, admin_or_contract: felt
) {
    _onlyAdmin();
    // TODO: event
    _collection_data.write(collection_id, (params, admin_or_contract));
    return ();
}

@external
func increase_attribute_balance_{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, bitwise_ptr: BitwiseBuiltin*, range_check_ptr}(
    attribute_id: felt, initial_balance: felt
) {
    alloc_locals;
    let collection_id = _get_collection_id(attribute_id);
    let (admin, contract) = _get_admin_or_contract(collection_id);
    with_attr error_message("Balance can only be increased on non-delegating attributes") {
        assert contract = 0;
    }
    with_attr error_message("Cannot increase the balance of a collection without an admin") {
        assert_not_zero(admin);
    }
    _only(admin);
    ERC1155_balance._increaseBalance(0, attribute_id, initial_balance);
    return ();
}




func _get_collection_id{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, bitwise_ptr: BitwiseBuiltin*, range_check_ptr}(
    attribute_id: felt,
) -> felt {
    let (collection_id) = bitwise_and(attribute_id, COLLECTION_ID_MASK);
    return collection_id;
}

func _has_contract{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, bitwise_ptr: BitwiseBuiltin*, range_check_ptr}(
    collection_id: felt,
) -> felt {
    let (parameters__admin_or_contract) = _collection_data.read(collection_id);
    let (has_contract) = bitwise_and(parameters__admin_or_contract[0], CONTRACT_BIT);
    return has_contract;
}


func _get_admin_or_contract{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, bitwise_ptr: BitwiseBuiltin*, range_check_ptr}(
    collection_id: felt,
) -> (admin: felt, contract: felt) {
    let (parameters__admin_or_contract) = _collection_data.read(collection_id);
    let (has_contract) = bitwise_and(parameters__admin_or_contract[0], CONTRACT_BIT);
    if (has_contract == CONTRACT_BIT) {
        return (0, parameters__admin_or_contract[1]);
    } else {
        return (parameters__admin_or_contract[1], 0);
    }
}
