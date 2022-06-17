# Briq proxy, freely derived from OZ but with a slightly different constructor.
# (unlike in OZ, I just initialize with an admin directly)

%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.math import assert_not_zero
from starkware.starknet.common.syscalls import library_call_l1_handler, library_call
from contracts.OZ.upgrades.library import (
    Proxy_implementation_address,
    Proxy_initializer,
    Proxy_set_implementation,
)

from contracts.upgrades.events import (
    ProxyAdminSet,
    ProxyImplementationSet,
)

#
# Constructor
#

@constructor
func constructor{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }(admin: felt, implentation_hash: felt):
    assert_not_zero(admin)
    assert_not_zero(implentation_hash)
    Proxy_initializer(admin)
    Proxy_set_implementation(implentation_hash)
    ProxyAdminSet.emit(admin)
    ProxyImplementationSet.emit(implentation_hash)
    return ()
end

#
# Fallback functions
#

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

    let (retdata_size: felt, retdata: felt*) = library_call(
        class_hash=address,
        function_selector=selector,
        calldata_size=calldata_size,
        calldata=calldata
    )

    return (retdata_size=retdata_size, retdata=retdata)
end

@l1_handler
@raw_input
func __l1_default__{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }(
        selector: felt,
        calldata_size: felt,
        calldata: felt*
    ):
    let (address) = Proxy_implementation_address.read()

    library_call_l1_handler(
        class_hash=address,
        function_selector=selector,
        calldata_size=calldata_size,
        calldata=calldata
    )

    return ()
end
