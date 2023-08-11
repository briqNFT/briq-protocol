//###########
//###########
//###########
// Storage variables.

#[contract]
mod Balance {
    use briq_protocol::utils::TempContractAddress;
    use briq_protocol::utils;

    struct Storage {
        _balance: LegacyMap<TempContractAddress, felt252>,
        _owner: LegacyMap<felt252, TempContractAddress>,
    }

    // @view
    fn ownerOf_(token_id: felt252) -> TempContractAddress {
        // OZ ∆: don't fail on res == 0
        _owner::read(token_id)
    }

    // @view
    fn balanceOf_(owner: TempContractAddress) -> felt252 {
        // OZ ∆: No 0 check, I don't see the point.
        _balance::read(owner)
    }

    fn _increaseBalance(owner: TempContractAddress) {
        let balance = _balance::read(owner);
        assert(balance < balance + 1, 'Mint would overflow balance');
        _balance::write(owner, balance + 1);
        return ();
    }

    fn _decreaseBalance(
        owner: TempContractAddress
    ) {
        let balance = _balance::read(owner);
        assert(balance - 1 < balance, 'Insufficient balance');
        _balance::write(owner, balance - 1);
        return ();
    }
}
