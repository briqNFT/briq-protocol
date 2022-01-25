%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.starknet.common.syscalls import get_caller_address
from starkware.starknet.common.syscalls import call_contract, delegate_l1_handler, delegate_call

from contracts.proxy.library import (
    Proxy_implementation_address,
    Proxy_set_implementation,
    Proxy_admin
)

####################
####################
####################
# Authorization patterns

func _onlyAdmin{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    } ():
    let (caller) = get_caller_address()
    let (admin) = Proxy_admin.read()
    if (caller - admin) == 0:
        return ()
    end
    # Failure
    with_attr error_message("You are not authorized to call this function"):
        assert 0 = 1
    end
    return ()
end

func _onlyAdminAnd{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    } (address: felt):
    let (caller) = get_caller_address()
    if (caller - address) == 0:
        return ()
    end
    _onlyAdmin()
    return ()
end


####################
####################
####################
# Backend proxies don't delegate the calls, but instead call.
# This is because the backend proxy handles authorization,
# the actual backend contract only checks that its caller is the proxy.

func _constructor{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    } (owner: felt):
    Proxy_admin.write(owner)
    return ()
end

@external
func setImplementation{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    } (new_implementation: felt):
    _onlyAdmin()
    Proxy_set_implementation(new_implementation)
    return()
end

@external
func setAdmin{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    } (new_admin: felt):
    _onlyAdmin()
    Proxy_admin.write(new_admin)
    return()
end


####################
####################
####################
# Forwarded calls

## Fallback method - can be called by admins.
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
    _onlyAdmin()

    let (address) = Proxy_implementation_address.read()

    let (retdata_size: felt, retdata: felt*) = call_contract(
        contract_address=address,
        function_selector=selector,
        calldata_size=calldata_size,
        calldata=calldata
    )

    return (retdata_size=retdata_size, retdata=retdata)
end

## TODO: L1 handler
