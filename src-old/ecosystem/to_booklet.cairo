#[contract]
mod toBooklet {
    use briq_protocol::utilities::authorization::Auth::_onlyAdmin;
    use briq_protocol::utils::TempContractAddress;

    struct Storage {
        booklet_address: TempContractAddress,
    }

    fn get() -> TempContractAddress {
        return booklet_address::read();
    }

    fn set(addr: TempContractAddress) {
        _onlyAdmin();
        booklet_address::write(addr)
    }
}
