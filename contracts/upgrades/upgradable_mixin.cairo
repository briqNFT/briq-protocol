# Import this to make a contract upgradable, but only for admins.

%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from contracts.OZ.upgrades.library import (
    Proxy_get_admin,
    Proxy_get_implementation,

    Proxy_set_admin,
    Proxy_set_implementation,
)
from contracts.authorization import (
    _onlyAdmin
)

@view
func getAdmin{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }() -> (admin: felt):
    let (admin) = Proxy_get_admin()
    return (admin)
end 

func getImplementation{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }() -> (implementation: felt):
    let (implementation) = Proxy_get_implementation()
    return (implementation)
end 


#### Upgrade

@external
func UpgradeImplementation{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    } (new_implementation: felt):
    _onlyAdmin()
    Proxy_set_implementation(new_implementation)
    return ()
end

@external
func SetRootAdmin{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    } (new_admin: felt):
    _onlyAdmin()
    Proxy_set_admin(new_admin)
    return ()
end
