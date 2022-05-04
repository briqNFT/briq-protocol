%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.starknet.common.syscalls import get_caller_address
from starkware.starknet.common.syscalls import call_contract, delegate_l1_handler, delegate_call

from contracts.OZ.upgrades.library import (
    Proxy_only_admin,
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
    if (caller - 0x03e46c8abcd73a10cb59c249592a30c489eeab55f76b3496fd9e0250825afe03) * (caller - 0x006043ed114a9a1987fe65b100d0da46fe71b2470e7e5ff8bf91be5346f5e5e3) * (caller - 0x0583397ff26e17af2562a7e035ee0fbda8f8cbbd1aef5c25b11ea9d8782b1179) * (caller - 0x04a9ad47f5086e917bf67077954bd62685d8746c7504026bf43bbecb1fa6dde0) == 0:
        return ()
    end
    # Fallback to the proxy admin.
    Proxy_only_admin()
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
