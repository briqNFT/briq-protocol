%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin, SignatureBuiltin

from contracts.utilities.authorization import (
    _onlyAdmin,
)

@storage_var
func _set_address() -> (address: felt):
end

@view
func getSetAddress_{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
    } () -> (address: felt):
    let (value) = _set_address.read()
    return (value)
end

@external
func setSetAddress_{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
    } (address: felt):
    _onlyAdmin()
    _set_address.write(address)
    return ()
end
