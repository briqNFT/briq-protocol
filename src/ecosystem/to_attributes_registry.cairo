#[contract]
mod toAttributesRegistry {
    use briq_protocol::utilities::authorization::Auth::_onlyAdmin;
    use briq_protocol::utils::TempContractAddress;
    use briq_protocol::utils::GetCallerAddress;

    struct Storage {
        ar_address: TempContractAddress,
    }

    fn get() -> TempContractAddress {
        return ar_address::read();
    }

    fn set(addr: TempContractAddress) {
        _onlyAdmin();
        ar_address::write(addr)
    }

    fn _onlyAttributesRegistry() {
        //with_attr error_message("Only the attributes registry may call this function.") {
        assert(GetCallerAddress() == ar_address::read(), 'Unauthorized');
    }

}
