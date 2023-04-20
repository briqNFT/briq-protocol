//from contracts.upgrades.upgradable_mixin import (
//    getAdmin_,
//    getImplementation_,
//    upgradeImplementation_,
//    setRootAdmin_,
//)

//from contracts.ecosystem.to_set import (
//    getSetAddress_,
//    setSetAddress_,
//)

//from contracts.attributes_registry.collections import (
//    create_collection_,
//    increase_attribute_balance_,
//)

//from contracts.attributes_registry.attributes import (
//    assign_attribute,
//    remove_attribute,
//    assign_attributes,
//    remove_attributes,
//    has_attribute,
//    total_balance,
//    token_uri,
//)

mod collections;
mod attributes;

#[contract]
mod AttributesRegistry {
    use starknet::ContractAddress;
    use traits::Into;
    use traits::TryInto;
    use option::OptionTrait;

    use briq_protocol::attributes_registry::collections::Collections;

    #[external]
    fn create_collection_(collection_id: felt252, params: felt252, admin_or_contract: felt252) {
        Collections::create_collection_(collection_id, params, admin_or_contract);
    }

    #[external]
    fn increase_attribute_balance_(attribute_id: felt252, initial_balance: felt252) {
        Collections::increase_attribute_balance_(attribute_id, initial_balance);
    }

    use briq_protocol::attributes_registry::attributes::Attributes;
    use briq_protocol::attributes_registry::attributes::Attributes::ShapeItem;
    use briq_protocol::attributes_registry::attributes::Attributes::FTSpec;

    #[external]
    fn assign_attributes(
        set_owner: ContractAddress,
        set_token_id: felt252,
        mut attributes: Array<felt252>,
        shape: Array<ShapeItem>,
        fts: Array<FTSpec>,
        nfts: Array<felt252>,
    ) {
        Attributes::assign_attributes(set_owner.into(), set_token_id, ref attributes, @shape, @fts, @nfts);
    }

    #[external]
    fn assign_attribute(
        set_owner: ContractAddress,
        set_token_id: felt252,
        attribute_id: felt252,
        shape: Array<ShapeItem>,
        fts: Array<FTSpec>,
        nfts: Array<felt252>,
    ) {
        Attributes::assign_attribute(set_owner.into(), set_token_id, attribute_id, @shape, @fts, @nfts);
    }

    #[external]
    fn remove_attributes(
        set_owner: ContractAddress,
        set_token_id: felt252,
        mut attributes: Array<felt252>
    ) {
        Attributes::remove_attributes(set_owner.into(), set_token_id, ref attributes);
    }

    #[external]
    fn remove_attribute(
        set_owner: ContractAddress,
        set_token_id: felt252,
        attribute_id: felt252,
    ) {
        Attributes::remove_attribute(set_owner.into(), set_token_id, attribute_id);
    }

    #[view]
    fn has_attribute(
        set_token_id: felt252, attribute_id: felt252
    ) -> bool  {
        return Attributes::has_attribute(set_token_id, attribute_id);
    }

    #[view]
    fn total_balance(
        owner: ContractAddress
    ) -> felt252 {
        return Attributes::total_balance(owner.into());
    }

    use briq_protocol::ecosystem::to_set::toSet;

    #[view]
    fn getSetAddress_() -> ContractAddress {
        return toSet::get().try_into().unwrap();
    }

    #[external]
    fn setSetAddress_(addr: ContractAddress) {
        return toSet::set(addr.into());
    }
}
