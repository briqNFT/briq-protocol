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
    let (caller) = get_caller_address()
    # Hardcoded briq team addresses.
    if (caller - 0x03e46c8abcd73a10cb59c249592a30c489eeab55f76b3496fd9e0250825afe03) * (caller - 0x006043ed114a9a1987fe65b100d0da46fe71b2470e7e5ff8bf91be5346f5e5e3) == 0:
        return ()
    end
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
