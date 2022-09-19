%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin, SignatureBuiltin

from contracts.utilities.authorization import _onlyAdmin

@storage_var
func _booklet_address() -> (address: felt) {
}

@view
func getBookletAddress_{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (
    address: felt
) {
    let (value) = _booklet_address.read();
    return (value,);
}

@external
func setBookletAddress_{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    address: felt
) {
    _onlyAdmin();
    _booklet_address.write(address);
    return ();
}
