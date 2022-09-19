// Import this to make a contract upgradable, but only for admins.
// To turn off upgradability, simply remove the mixin from the contract and upgrade one last time.

%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.math import assert_not_zero
from contracts.OZ.upgrades.library import (
    Proxy_get_admin,
    Proxy_get_implementation,
    Proxy_set_admin,
    Proxy_set_implementation,
)
from contracts.utilities.authorization import _onlyAdmin

from contracts.upgrades.events import ProxyAdminSet, ProxyImplementationSet

@view
func getAdmin_{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (admin: felt) {
    let (admin) = Proxy_get_admin();
    return (admin,);
}

@view
func getImplementation_{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (
    implementation: felt
) {
    let (implementation) = Proxy_get_implementation();
    return (implementation,);
}

// ### Upgrade

@external
func upgradeImplementation_{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    new_implementation: felt
) {
    _onlyAdmin();
    assert_not_zero(new_implementation);
    Proxy_set_implementation(new_implementation);
    ProxyImplementationSet.emit(new_implementation);
    return ();
}

@external
func setRootAdmin_{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    new_admin: felt
) {
    _onlyAdmin();
    assert_not_zero(new_admin);
    Proxy_set_admin(new_admin);
    ProxyAdminSet.emit(new_admin);
    return ();
}
