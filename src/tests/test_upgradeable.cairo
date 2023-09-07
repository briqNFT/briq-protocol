use traits::{Into, TryInto, Default};
use option::{Option, OptionTrait};
use result::ResultTrait;
use array::ArrayTrait;
use serde::Serde;
use starknet::{ContractAddress, ClassHash};

use briq_protocol::tests::test_utils::{
    deploy_default_world, impersonate, DefaultWorld, DEFAULT_OWNER, WORLD_ADMIN
};
use dojo::world::{IWorldDispatcher, IWorldDispatcherTrait};
use briq_protocol::briq_token::BriqToken;
use briq_protocol::briq_token::BriqToken::{Event, Upgraded};
use briq_protocol::tests::contract_upgrade::ContractUpgrade;
use briq_protocol::tests::contract_upgrade::ContractUpgrade::{
    IUselessContract, IUselessContractDispatcher, IUselessContractDispatcherTrait
};
use briq_protocol::upgradeable::{IUpgradeable, IUpgradeableDispatcher, IUpgradeableDispatcherTrait};


fn test_upgrade_with_admin(contract_address: ContractAddress) {
    impersonate(WORLD_ADMIN());

    let new_class_hash: ClassHash = ContractUpgrade::TEST_CLASS_HASH.try_into().unwrap();
    let upgradable_dispatcher = IUpgradeableDispatcher { contract_address };

    upgradable_dispatcher.upgrade(new_class_hash);

    let upgraded = IUselessContractDispatcher { contract_address };
    assert(upgraded.plz_more_tps() == 'daddy', 'quantum leap failed');
}

fn test_upgrade_with_non_admin(contract_address: ContractAddress) {
    impersonate(DEFAULT_OWNER());

    let new_class_hash: ClassHash = ContractUpgrade::TEST_CLASS_HASH.try_into().unwrap();
    let upgradable_dispatcher = IUpgradeableDispatcher { contract_address };

    upgradable_dispatcher.upgrade(new_class_hash); // should panic
}

//
// briq_token
//

#[test]
#[available_gas(30000000)]
fn test_upgrade_with_admin_briq_token() {
    let DefaultWorld{world, briq_token, .. } = deploy_default_world();
    test_upgrade_with_admin(briq_token.contract_address);
}


#[test]
#[available_gas(30000000)]
#[should_panic]
fn test_upgrade_with_non_admin_briq_token() {
    let DefaultWorld{world, briq_token, .. } = deploy_default_world();
    test_upgrade_with_non_admin(briq_token.contract_address);
}


#[test]
#[available_gas(30000000)]
fn test_briq_token_upgrade_emit_event() {
    let DefaultWorld{world, briq_token, .. } = deploy_default_world();

    impersonate(WORLD_ADMIN());

    let new_class_hash: ClassHash = ContractUpgrade::TEST_CLASS_HASH.try_into().unwrap();

    let briq_token_upgradable = IUpgradeableDispatcher {
        contract_address: briq_token.contract_address
    };

    briq_token_upgradable.upgrade(new_class_hash);

    // Upgraded
    assert(
        @starknet::testing::pop_log(briq_token_upgradable.contract_address)
            .unwrap() == @Event::Upgraded(Upgraded { class_hash: new_class_hash }),
        'invalid Upgraded event'
    );
}

//
// set_nft
//

#[test]
#[available_gas(30000000)]
fn test_upgrade_with_admin_generic_sets() {
    let DefaultWorld{world, generic_sets, .. } = deploy_default_world();
    test_upgrade_with_admin(generic_sets.contract_address);
}


#[test]
#[available_gas(30000000)]
#[should_panic]
fn test_upgrade_with_non_admin_generic_sets() {
    let DefaultWorld{world, generic_sets, .. } = deploy_default_world();
    test_upgrade_with_non_admin(generic_sets.contract_address);
}


#[test]
#[available_gas(30000000)]
fn test_upgrade_with_admin_ducks_set() {
    let DefaultWorld{world, ducks_set, .. } = deploy_default_world();
    test_upgrade_with_admin(ducks_set.contract_address);
}


#[test]
#[available_gas(30000000)]
#[should_panic]
fn test_upgrade_with_non_admin_ducks_set() {
    let DefaultWorld{world, ducks_set, .. } = deploy_default_world();
    test_upgrade_with_non_admin(ducks_set.contract_address);
}


//
// booklet
//

#[test]
#[available_gas(30000000)]
fn test_upgrade_with_admin_ducks_booklet() {
    let DefaultWorld{world, ducks_booklet, .. } = deploy_default_world();
    test_upgrade_with_admin(ducks_booklet.contract_address);
}


#[test]
#[available_gas(30000000)]
#[should_panic]
fn test_upgrade_with_non_admin_ducks_booklet() {
    let DefaultWorld{world, ducks_booklet, .. } = deploy_default_world();
    test_upgrade_with_non_admin(ducks_booklet.contract_address);
}


#[test]
#[available_gas(30000000)]
fn test_upgrade_with_admin_planets_booklet() {
    let DefaultWorld{world, planets_booklet, .. } = deploy_default_world();
    test_upgrade_with_admin(planets_booklet.contract_address);
}


#[test]
#[available_gas(30000000)]
#[should_panic]
fn test_upgrade_with_non_admin_planets_booklet() {
    let DefaultWorld{world, planets_booklet, .. } = deploy_default_world();
    test_upgrade_with_non_admin(planets_booklet.contract_address);
}


//
// boxes
//

#[test]
#[available_gas(30000000)]
fn test_upgrade_with_admin_box_nft() {
    let DefaultWorld{world, box_nft, .. } = deploy_default_world();
    test_upgrade_with_admin(box_nft.contract_address);
}


#[test]
#[available_gas(30000000)]
#[should_panic]
fn test_upgrade_with_non_admin_box_nft() {
    let DefaultWorld{world, box_nft, .. } = deploy_default_world();
    test_upgrade_with_non_admin(box_nft.contract_address);
}

