#[contract]
mod toAttributesRegistry {
    use briq_protocol::utilities::authorization::Auth::_onlyAdmin;
    use briq_protocol::utils::TempContractAddress;

    struct Storage {
        address: TempContractAddress,
    }

    fn get() -> TempContractAddress {
        return address::read();
    }

    fn set(addr: TempContractAddress) {
        _onlyAdmin();
        address::write(addr)
    }
}
