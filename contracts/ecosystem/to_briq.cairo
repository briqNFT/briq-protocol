%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin, SignatureBuiltin

from contracts.utilities.authorization import _onlyAdmin

@storage_var
func _briq_address() -> (address: felt) {
}

@view
func getBriqAddress_{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (
    address: felt
) {
    let (value) = _briq_address.read();
    return (value,);
}

@external
func setBriqAddress_{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    address: felt
) {
    _onlyAdmin();
    _briq_address.write(address);
    return ();
}
