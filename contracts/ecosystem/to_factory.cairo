%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin, SignatureBuiltin

from contracts.utilities.authorization import _onlyAdmin

@storage_var
func _factory_address() -> (address: felt) {
}

@view
func getFactoryAddress_{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (
    address: felt
) {
    let (value) = _factory_address.read();
    return (value,);
}

@external
func setFactoryAddress_{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    address: felt
) {
    _onlyAdmin();
    _factory_address.write(address);
    return ();
}
