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

#[contract]
mod AttributesRegistry {
    use briq_protocol::utilities::authorization::Auth::_onlyAdmin;
    use briq_protocol::ecosystem::to_set::Storj;

    use starknet::ContractAddress;
    use option::OptionTrait;
    use traits::Into;
    use starknet::ContractAddressIntoFelt252;
    use traits::TryInto;
    use starknet::Felt252TryIntoContractAddress;

    struct Storage {
        to_set: Storj,
    }

    #[view]
    fn getSetAddress_() -> ContractAddress {
        let toto: Option<ContractAddress> = to_set::read().address.try_into();
        toto.expect('not an address')
    }

    #[external]
    fn setSetAddress_(addr: ContractAddress) {
        _onlyAdmin();
        to_set::write(Storj { address: addr.into() })
    }
}
