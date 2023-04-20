#[contract]
mod toSet {
    use briq_protocol::utilities::authorization::Auth::_onlyAdmin;
    use briq_protocol::utils::TempContractAddress;

    struct Storage {
        set_address: TempContractAddress,
    }

    fn get() -> TempContractAddress {
        return set_address::read();
    }

    fn set(addr: TempContractAddress) {
        _onlyAdmin();
        set_address::write(addr)
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
