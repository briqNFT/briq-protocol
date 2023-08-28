use traits::{Into, TryInto, Default};
use option::{Option, OptionTrait};
use result::ResultTrait;
use array::ArrayTrait;
use serde::Serde;
use starknet::ClassHash;

use briq_protocol::tests::test_utils::{
    deploy_default_world, impersonate, DefaultWorld, DEFAULT_OWNER, WORLD_ADMIN
};
use briq_protocol::world_config::{WorldConfig, SYSTEM_CONFIG_ID};
use dojo::world::{IWorldDispatcher, IWorldDispatcherTrait};
use briq_protocol::briq_token::BriqToken;
use briq_protocol::briq_token::BriqToken::{Event, Upgraded};
use briq_protocol::upgradeable::{IUpgradeable, IUpgradeableDispatcher, IUpgradeableDispatcherTrait};
use briq_protocol::tests::contract_upgrade::ContractUpgrade;
use briq_protocol::tests::contract_upgrade::ContractUpgrade::{
    IUselessContract, IUselessContractDispatcher, IUselessContractDispatcherTrait
};


#[test]
#[available_gas(30000000)]
fn test_briq_token_upgrade_emit_event() {
    let DefaultWorld{world, briq_token, set_nft, .. } = deploy_default_world();

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
