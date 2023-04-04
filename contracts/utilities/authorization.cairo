#[contract]
mod Auth {
    use starknet::get_caller_address;
    use starknet::ContractAddress;

    #[view]
    fn _only(address: ContractAddress) {
        let caller = get_caller_address();
        if caller != address {
            assert(false, 'Not authorized');
        }
    }
}

//%lang starknet

//from starkware.cairo.common.cairo_builtins import HashBuiltin
//from starkware.starknet.common.syscalls import get_caller_address
//from contracts.vendor.openzeppelin.upgrades.library import Proxy

//###################
//###################
//###################
// Authorization patterns

//func _only{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(address: felt) {
//    let (caller) = get_caller_address();
//    if ((caller - address) == 0) {
//        return ();
//    }
//    // Failure
//    with_attr error_message("You are not authorized to call this function") {
//        assert 0 = 1;
//    }
//    return ();
//}
//
//func _onlyAdmin{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
//    let (caller) = get_caller_address();
//    // Hardcoded briq team addresses.
//    if ((caller - 0x03eF5b02BCc5D30f3f0D35d55F365E6388fE9501eca216Cb1596940bf41083E2) * (caller - 0x059dF66aF2E0E350842b11EA6B5a903b94640C4ff0418b04CceDcC320F531A08) == 0) {
//        return ();
//    }
//    // Fallback to the proxy admin.
//    Proxy.assert_only_admin();
//    return ();
//}
//
//func _onlyAdminAnd{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(address: felt) {
//    let (caller) = get_caller_address();
//    if ((caller - address) == 0) {
//        return ();
//    }
//    _onlyAdmin();
//    return ();
//}
