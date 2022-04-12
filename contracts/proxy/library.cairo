%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.starknet.common.syscalls import get_caller_address

#
# Storage variables
#

@storage_var
func Proxy_implementation_address() -> (implementation_address: felt):
end

@storage_var
func Proxy_admin() -> (proxy_admin: felt):
end

@storage_var
func Proxy_initialized() -> (initialized: felt):
end

#
# Initialize
#

func Proxy_initializer{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }(proxy_admin: felt):
    let (initialized) = Proxy_initialized.read()
    assert initialized = 0
    Proxy_initialized.write(1)
    Proxy_admin.write(proxy_admin)
    return ()
end

#
# Upgrades
#

func Proxy_set_implementation{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }(new_implementation: felt):
    Proxy_implementation_address.write(new_implementation)
    return ()
end

#
# Guards
#

func Proxy_is_admin{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }() -> (is_admin:felt):
    let (caller) = get_caller_address()
    let (admin) = Proxy_admin.read()
    if admin == caller:
        return (1)
    end
    return (0)
end
