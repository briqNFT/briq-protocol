#[contract]
mod toBox {
    use briq_protocol::utilities::authorization::Auth::_onlyAdmin;
    use briq_protocol::utils::TempContractAddress;

    struct Storage {
        box_address: TempContractAddress,
    }

    fn get() -> TempContractAddress {
        return box_address::read();
    }

    fn set(addr: TempContractAddress) {
        _onlyAdmin();
        box_address::write(addr)
    }
}
