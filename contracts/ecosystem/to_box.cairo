%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin, SignatureBuiltin

from contracts.utilities.authorization import _onlyAdmin

@storage_var
func _box_address() -> (address: felt) {
}

@view
func getBoxAddress_{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (
    address: felt
) {
    let (value) = _box_address.read();
    return (value,);
}

@external
func setBoxAddress_{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    address: felt
) {
    _onlyAdmin();
    _box_address.write(address);
    return ();
}
