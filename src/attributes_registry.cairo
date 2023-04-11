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
        set_owner: felt252,
        set_token_id: felt252,
        mut attributes: Array<felt252>,
        ref shape: Array<ShapeItem>,
        ref fts: Array<FTSpec>,
        ref nfts: Array<felt252>,
    ) {
        Attributes::assign_attributes(set_owner, set_token_id, attributes, ref shape, ref fts, ref nfts);
    }

    #[external]
    fn assign_attribute(
        set_owner: felt252,
        set_token_id: felt252,
        attribute_id: felt252,
        ref shape: Array<ShapeItem>,
        ref fts: Array<FTSpec>,
        ref nfts: Array<felt252>,
    ) {
        Attributes::assign_attribute(set_owner, set_token_id, attribute_id, ref shape, ref fts, ref nfts);
    }

    #[external]
    fn remove_attributes(
        set_owner: felt252,
        set_token_id: felt252,
        mut attributes: Array<felt252>
    ) {
        Attributes::remove_attributes(set_owner, set_token_id, attributes);
    }

    #[external]
    fn remove_attribute(
        set_owner: felt252,
        set_token_id: felt252,
        attribute_id: felt252,
    ) {
        Attributes::remove_attribute(set_owner, set_token_id, attribute_id);
    }

    #[view]
    fn has_attribute(
        set_token_id: felt252, attribute_id: felt252
    ) -> felt252  {
        return Attributes::has_attribute(set_token_id, attribute_id);
    }

    #[view]
    fn total_balance(
        owner: felt252
    ) -> felt252 {
        return Attributes::total_balance(owner);
    }
    


    use briq_protocol::ecosystem::to_set::ToSet;

    #[view]
    fn getSetAddress_() -> ContractAddress {
        return ToSet::getSetAddress_();
    }

    #[external]
    fn setSetAddress_(addr: ContractAddress) {
        return ToSet::setSetAddress_(addr);
    }
}