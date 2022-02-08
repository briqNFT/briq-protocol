%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.starknet.common.syscalls import delegate_l1_handler, delegate_call
from starkware.cairo.common.alloc import alloc

from contracts.proxy.library import (
    Proxy_implementation_address,
    Proxy_admin,
    Proxy_initialized,

    Proxy_initializer,
    Proxy_set_implementation,
    Proxy_only_admin,
)

#
# Constructor
#

@constructor
func constructor{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    } (admin: felt, implementation_address: felt):
    alloc_locals
    Proxy_initializer(admin)
    Proxy_set_implementation(implementation_address)
    return ()
end

##

@external
func setAdmin{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    } (new_admin: felt):
    Proxy_only_admin()
    Proxy_admin.write(new_admin)
    return ()
end
##

@external
func setImplementation{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    } (new_implementation: felt):
    Proxy_only_admin()
    Proxy_set_implementation(new_implementation)
    return ()
end

## Getters

@view
func getImplementation{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr} () -> (address: felt):
    let (addr) = Proxy_implementation_address.read()
    return (addr)
end

@view
func getInitialized{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr} () -> (initialized: felt):
    let (val) = Proxy_initialized.read()
    return (val)
end

@view
func getAdmin{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr} () -> (address: felt):
    let (addr) = Proxy_admin.read()
    return (addr)
end

## Fallback

@external
@raw_input
@raw_output
func __default__{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }(
        selector: felt,
        calldata_size: felt,
        calldata: felt*
    ) -> (
        retdata_size: felt,
        retdata: felt*
    ):
    let (address) = Proxy_implementation_address.read()

    let (retdata_size: felt, retdata: felt*) = delegate_call(
        contract_address=address,
        function_selector=selector,
        calldata_size=calldata_size,
        calldata=calldata
    )

    return (retdata_size=retdata_size, retdata=retdata)
end
