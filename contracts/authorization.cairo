%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.starknet.common.syscalls import get_caller_address
from starkware.starknet.common.syscalls import call_contract, delegate_l1_handler, delegate_call

from contracts.proxy.library import (
    Proxy_admin,
)

####################
####################
####################
# Authorization patterns

func _only{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    } (address: felt):
    let (caller) = get_caller_address()
    if (caller - address) == 0:
        return ()
    end
    # Failure
    with_attr error_message("You are not authorized to call this function"):
        assert 0 = 1
    end
    return ()
end

func _onlyAdmin{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    } ():
    let (admin) = Proxy_admin.read()
    _only(admin)
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
