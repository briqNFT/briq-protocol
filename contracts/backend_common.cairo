%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.starknet.common.syscalls import get_caller_address

@storage_var
func _proxy_address() -> (address: felt):
end

func _onlyProxy{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    } ():
    let (caller) = get_caller_address()
    let (proxy) = _proxy_address.read()
    assert caller = proxy
    return ()
end


@external
func setProxyAddress{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    } (address: felt):
    _onlyProxy()
    _proxy_address.write(address)
    return ()
end
