#[contract]
mod toBriq {
    use briq_protocol::utilities::authorization::Auth::_onlyAdmin;
    use briq_protocol::utils::TempContractAddress;

    struct Storage {
        briq_address: TempContractAddress,
    }

    fn get() -> TempContractAddress {
        return briq_address::read();
    }

    fn set(addr: TempContractAddress) {
        _onlyAdmin();
        briq_address::write(addr)
    }
}
