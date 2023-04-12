#[contract]
mod toAttributesRegistry {
    use briq_protocol::utilities::authorization::Auth::_onlyAdmin;
    use briq_protocol::utils::TempContractAddress;

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
}
