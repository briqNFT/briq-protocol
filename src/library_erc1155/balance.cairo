
#[contract]
mod Balance {
    use gas::withdraw_gas_all;
    use gas::get_builtin_costs;

    use traits::Copy;
    use traits::Into;
    use traits::TryInto;
    use option::OptionTrait;

    use array::SpanTrait;
    use array::ArrayTrait;
    use array::ArrayTCloneImpl;
    use clone::Clone;

    use briq_protocol::utils::TempContractAddress;
    use briq_protocol::utils::GetCallerAddress;
    
    use briq_protocol::utils;
    use briq_protocol::utils::check_gas;

    struct Storage {
        _balance: LegacyMap<(TempContractAddress, felt252), felt252>,
    }

    fn _increaseBalance(owner: TempContractAddress, token_id: felt252, number: felt252) {
        let balance = _balance::read((owner, token_id));
        assert(balance < balance + number, 'Mint would overflow balance');
        _balance::write((owner, token_id), balance + number);
        return ();
    }

    fn _decreaseBalance(
        owner: TempContractAddress, token_id: felt252, number: felt252,
    ) {
        let balance = _balance::read((owner, token_id));
        assert(balance - number < balance, 'Insufficient balance');
        _balance::write((owner, token_id), balance - number);
        return ();
    }

    // @view
    fn balanceOf_(
        owner: TempContractAddress, token_id: felt252
    ) -> felt252 {
        return _balance::read((owner, token_id));
    }

    // @view
    //fn balanceOfBatch_(
    //    mut owners: Array<ContractAddress>, mut token_ids: Array<felt252>
    //) -> Array<felt252> {
    //    assert(owners.len() == token_ids.len(), 'Bad input');
    //    let mut balances = ArrayTrait::<felt252>::new();
    //    loop {
    //        if owners.len() == 0_u32 {
    //            break 0;
    //        }
    //        let balance = _balance::read((*owners.at(0_u32), *token_ids.at(0_u32)));
    //        balances.append(balance);
    //        owners.pop_front();
    //        token_ids.pop_front();
    //    };
    //    return balances;
    //}

    fn balanceOfBatch_(
        mut owners: Array<TempContractAddress>, mut token_ids: Array<felt252>
    ) -> Array<felt252> {
        assert(owners.len() == token_ids.len(), 'Bad input');
        return _balanceOfBatch_(owners, token_ids, ArrayTrait::<felt252>::new());
    }

    fn _balanceOfBatch_(
        mut owners: Array<TempContractAddress>, mut token_ids: Array<felt252>, mut balances: Array<felt252>
    ) -> Array<felt252> {
        check_gas();
        if owners.len() == 0_u32 {
            return balances;
        }
        let balance = _balance::read((*owners.at(0_u32), *token_ids.at(0_u32)));
        balances.append(balance);
        owners.pop_front();
        token_ids.pop_front();
        return _balanceOfBatch_(owners, token_ids, balances);
    }
}
