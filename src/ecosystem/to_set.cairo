#[contract]
mod ToSet {
    use briq_protocol::utilities::authorization::Auth::_onlyAdmin;
    use starknet::ContractAddress;

    struct Storage {
        address: ContractAddress,
    }

    use option::OptionTrait;
    use traits::Into;
    use starknet::ContractAddressIntoFelt252;
    use traits::TryInto;
    use starknet::Felt252TryIntoContractAddress;

    //#[view]
    fn getSetAddress_() -> ContractAddress {
        return address::read();
    }

    //#[external]
    fn setSetAddress_(addr: ContractAddress) {
        _onlyAdmin();
        address::write(addr)
    }
}

//@storage_var
//func _set_address() -> (address: felt) {
//}

//@view
//func getSetAddress_{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (
//    address: felt
//) {
//    let (value) = _set_address.read();
//    return (value,);
//}
//
//@external
//func setSetAddress_{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
//    address: felt
//) {
//    _onlyAdmin();
//    _set_address.write(address);
//    return ();
//}
