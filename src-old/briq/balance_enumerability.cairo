#[contract]
mod BalanceEnum {
    use traits::Into;
    use option::OptionTrait;
    use array::ArrayTrait;

    use briq_protocol::library_erc1155::balance::Balance;
    use briq_protocol::utils::check_gas;
    use briq_protocol::utils;
    use briq_protocol::types::FTSpec;

    struct Storage {
        // Enumerate materials per owner.
        // TODO: consider extending with the # of briqs per material, since material is 0-2^64
        _material_by_owner: LegacyMap<(felt252, felt252), felt252> //(owner: felt252, index: felt252) -> (material: felt252) {
    }

    #[view]
    fn balanceOfMaterials(owner: felt252, materials: Array<felt252>) -> Array<felt252> { //(balances_len: felt252, balances: felt252*) {
        _balanceOfMaterialsImpl(owner, materials, ArrayTrait::<felt252>::new())
    }

    fn _balanceOfMaterialsImpl(owner: felt252, mut materials: Array<felt252>, mut out: Array<felt252>) -> Array<felt252> {
        check_gas();
        if materials.len() == 0 {
            return out;
        }
        out.append(Balance::balanceOf_(owner, materials.pop_front().unwrap()));
        return _balanceOfMaterialsImpl(owner, materials, out);
    }

    #[view]
    fn materialsOf(owner: felt252) -> Array<felt252> { //materials_len: felt252, materials: felt252*
        _materialsOfImpl(owner, ArrayTrait::<felt252>::new())
    }

    fn _materialsOfImpl(owner: felt252, mut mats: Array<felt252>) -> Array<felt252> {
        check_gas();
        let mat = _material_by_owner::read((owner, mats.len().into()));
        if mat != 0 {
            mats.append(mat);
            return _materialsOfImpl(owner, mats);
        }
        return mats;
    }

    // NB: slightly less efficient than doing it manually.
    #[view]
    fn fullBalanceOf(owner: felt252) -> Array<FTSpec> { //(balances_len: felt252, balances: BalanceSpec*) {
        _fullBalanceOfImpl(owner, ArrayTrait::<FTSpec>::new())
    }

    fn _fullBalanceOfImpl(owner: felt252, mut out: Array<FTSpec>) -> Array<FTSpec> { //) -> (balances_len: felt252, balances: BalanceSpec*) {
        check_gas();
        let mat = _material_by_owner::read((owner, out.len().into()));
        if mat == 0 {
            return out;
        }
        out.append(FTSpec { token_id: mat, qty: Balance::balanceOf_(owner, mat) });
        return _fullBalanceOfImpl(owner, out);
    }

    // //##############
    // //##############
    // // Token setting helpers

    // Store the new token id in the list, at an empty slot (marked by 0).
    // If the item already exists in the list, do nothing.
    fn _setMaterialByOwner(owner: felt252, material: felt252, index: felt252) {
        check_gas();
        let token_id = _material_by_owner::read((owner, index));
        if token_id == material {
            return ();
        }
        if token_id == 0 {
            _material_by_owner::write((owner, index), material);
            return ();
        }
        return _setMaterialByOwner(owner, material, index + 1);
    }

    // Unset the material from the list if the balance is 0. Swap and pop idiom.
    // NB: the item is asserted to be in the list.
    fn _maybeUnsetMaterialByOwner(owner: felt252, material: felt252) {
        check_gas();
        let balance = Balance::_balance::read((owner, material));
        if balance != 0 {
            return ();
        }
        return _unsetMaterialByOwner_searchPhase(owner, material, 0);
    }

    // During the search phase, we check for a matching token ID.
    fn _unsetMaterialByOwner_searchPhase(owner: felt252, material_id: felt252, index: felt252) {
        check_gas();
        let tok = _material_by_owner::read((owner, index));
        assert(tok != 0, 'Mat not in list');
        if tok == material_id {
            return _unsetMaterialByOwner_erasePhase(owner, 0, index + 1, index);
        }
        return _unsetMaterialByOwner_searchPhase(owner, material_id, index + 1);
    }

    // During the erase phase, we pass the last known value and the slot to insert it in, and go one past the end.
    fn _unsetMaterialByOwner_erasePhase(owner: felt252, last_known_value: felt252, index: felt252, target_index: felt252) {
        check_gas();
        let tok = _material_by_owner::read((owner, index));
        if tok != 0 {
            return _unsetMaterialByOwner_erasePhase(owner, tok, index + 1, target_index);
        }
        assert(target_index < index, 'Incoherent');
        _material_by_owner::write((owner, target_index), last_known_value);
        _material_by_owner::write((owner, index - 1), 0);
    }
}
