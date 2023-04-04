%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin, SignatureBuiltin
from starkware.starknet.common.syscalls import get_caller_address
from contracts.utilities.authorization import _onlyAdmin

@storage_var
func _attributes_registry_address() -> (address: felt) {
}

@view
func getAttributesRegistryAddress_{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (
    address: felt
) {
    let (value) = _attributes_registry_address.read();
    return (value,);
}

@external
func setAttributesRegistryAddress_{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    address: felt
) {
    _onlyAdmin();
    _attributes_registry_address.write(address);
    return ();
}

func _onlyAttributesRegistry{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    let (caller) = get_caller_address();
    let (attr_addr) = _attributes_registry_address.read();
    with_attr error_message("Only the attributes registry may call this function.") {
        assert caller = attr_addr;
    }
    return ();
}