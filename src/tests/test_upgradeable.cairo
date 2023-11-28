use traits::{Into, TryInto, Default};
use option::{Option, OptionTrait};
use result::ResultTrait;
use array::ArrayTrait;
use serde::Serde;
use starknet::{ContractAddress, ClassHash};

use briq_protocol::tests::test_utils::{
    spawn_briq_test_world, impersonate, DefaultWorld, DEFAULT_OWNER, WORLD_ADMIN
};
use dojo::world::{IWorldDispatcher, IWorldDispatcherTrait};
use briq_protocol::tests::contract_upgrade::{IUselessContract, IUselessContractDispatcher, IUselessContractDispatcherTrait};
use briq_protocol::tests::contract_upgrade::ContractUpgrade;
use dojo::components::upgradeable::{IUpgradeable, IUpgradeableDispatcher, IUpgradeableDispatcherTrait};


fn test_upgrade_with_admin(world: IWorldDispatcher, contract_address: ContractAddress) {
    impersonate(WORLD_ADMIN());

    let new_class_hash: ClassHash = ContractUpgrade::TEST_CLASS_HASH.try_into().unwrap();
    
    world.upgrade_contract(contract_address, new_class_hash);

    let upgraded = IUselessContractDispatcher { contract_address };
    assert(upgraded.i_request_additional_tps() == 'father', 'quantum leap failed');
}

fn test_upgrade_with_non_admin(world: IWorldDispatcher, contract_address: ContractAddress) {
    impersonate(DEFAULT_OWNER());

    let new_class_hash: ClassHash = ContractUpgrade::TEST_CLASS_HASH.try_into().unwrap();
    
    world.upgrade_contract(contract_address, new_class_hash);
}

//
// briq_token
//

#[test]
#[available_gas(300000000)]
fn test_upgrade_with_admin_briq_token() {
    let DefaultWorld{world, briq_token, .. } = spawn_briq_test_world();
    test_upgrade_with_admin(world, briq_token.contract_address);
}


#[test]
#[available_gas(300000000)]
#[should_panic]
fn test_upgrade_with_non_admin_briq_token() {
    let DefaultWorld{world, briq_token, .. } = spawn_briq_test_world();
    test_upgrade_with_non_admin(world, briq_token.contract_address);
}

use debug::PrintTrait;
#[test]
#[available_gas(300000000)]
fn test_briq_token_upgrade_emit_event() {
    let DefaultWorld{world, briq_token, .. } = spawn_briq_test_world();

    impersonate(WORLD_ADMIN());

    let new_class_hash: ClassHash = ContractUpgrade::TEST_CLASS_HASH.try_into().unwrap();

    world.upgrade_contract(briq_token.contract_address, new_class_hash);

    Into::<ClassHash, felt252>::into(starknet::testing::pop_log::<dojo::components::upgradeable::upgradeable::Upgraded>(briq_token.contract_address)
            .unwrap().class_hash).print();
    // Upgraded
    assert(
        starknet::testing::pop_log::<dojo::components::upgradeable::upgradeable::Upgraded>(briq_token.contract_address)
            .unwrap().class_hash == new_class_hash,
        'invalid Upgraded event'
    );
}

//
// set_nft
//

#[test]
#[available_gas(300000000)]
fn test_upgrade_with_admin_generic_sets() {
    let DefaultWorld{world, generic_sets, .. } = spawn_briq_test_world();
    test_upgrade_with_admin(world, generic_sets.contract_address);
}


#[test]
#[available_gas(300000000)]
#[should_panic]
fn test_upgrade_with_non_admin_generic_sets() {
    let DefaultWorld{world, generic_sets, .. } = spawn_briq_test_world();
    test_upgrade_with_non_admin(world, generic_sets.contract_address);
}


#[test]
#[available_gas(300000000)]
fn test_upgrade_with_admin_sets_ducks() {
    let DefaultWorld{world, sets_ducks, .. } = spawn_briq_test_world();
    test_upgrade_with_admin(world, sets_ducks.contract_address);
}


#[test]
#[available_gas(300000000)]
#[should_panic]
fn test_upgrade_with_non_admin_sets_ducks() {
    let DefaultWorld{world, sets_ducks, .. } = spawn_briq_test_world();
    test_upgrade_with_non_admin(world, sets_ducks.contract_address);
}


//
// booklet
//

#[test]
#[available_gas(300000000)]
fn test_upgrade_with_admin_booklet_ducks() {
    let DefaultWorld{world, booklet_ducks, .. } = spawn_briq_test_world();
    test_upgrade_with_admin(world, booklet_ducks.contract_address);
}


#[test]
#[available_gas(300000000)]
#[should_panic]
fn test_upgrade_with_non_admin_booklet_ducks() {
    let DefaultWorld{world, booklet_ducks, .. } = spawn_briq_test_world();
    test_upgrade_with_non_admin(world, booklet_ducks.contract_address);
}


#[test]
#[available_gas(300000000)]
fn test_upgrade_with_admin_booklet_sp() {
    let DefaultWorld{world, booklet_sp, .. } = spawn_briq_test_world();
    test_upgrade_with_admin(world, booklet_sp.contract_address);
}


#[test]
#[available_gas(300000000)]
#[should_panic]
fn test_upgrade_with_non_admin_booklet_sp() {
    let DefaultWorld{world, booklet_sp, .. } = spawn_briq_test_world();
    test_upgrade_with_non_admin(world, booklet_sp.contract_address);
}


//
// boxes
//

#[test]
#[available_gas(300000000)]
fn test_upgrade_with_admin_box_nft() {
    let DefaultWorld{world, box_nft, .. } = spawn_briq_test_world();
    test_upgrade_with_admin(world, box_nft.contract_address);
}


#[test]
#[available_gas(300000000)]
#[should_panic]
fn test_upgrade_with_non_admin_box_nft() {
    let DefaultWorld{world, box_nft, .. } = spawn_briq_test_world();
    test_upgrade_with_non_admin(world, box_nft.contract_address);
}

