use traits::{Into, TryInto, Default};
use option::{Option, OptionTrait};
use result::ResultTrait;
use array::ArrayTrait;
use serde::Serde;

use dojo::world::{IWorldDispatcher, IWorldDispatcherTrait};
use briq_protocol::world_config::{WorldConfig, SYSTEM_CONFIG_ID};
use briq_protocol::tests::test_utils::deploy_default_world;

use dojo_erc::erc721::interface::IERC721DispatcherTrait;

use briq_protocol::types::{FTSpec, ShapeItem};

use debug::PrintTrait;

use briq_protocol::attributes::collection::CreateCollectionData;

#[test]
#[available_gas(30000000)]
fn test_create_collections() {
    let DefaultWorld{world, .. } = deploy_default_world();

    {
        let mut calldata: Array<felt252> = ArrayTrait::new();
        CreateCollectionData {
            collection_id: 1,
            params: 2,
            admin_or_system: starknet::contract_address_const::<0xfafa>()
        }.serialize(ref calldata);
        world.execute('create_collection', (calldata));
    }

    {
        let mut calldata: Array<felt252> = ArrayTrait::new();
        CreateCollectionData {
            collection_id: 2,
            params: 2,
            admin_or_system: starknet::contract_address_const::<0xfafa>()
        }.serialize(ref calldata);
        world.execute('create_collection', (calldata));
    }
}

#[test]
#[available_gas(30000000)]
#[should_panic]
fn test_create_collection_collision() {
    let DefaultWorld{world, .. } = deploy_default_world();

    {
        let mut calldata: Array<felt252> = ArrayTrait::new();
        CreateCollectionData {
            collection_id: 1,
            params: 2,
            admin_or_system: starknet::contract_address_const::<0xfafa>()
        }.serialize(ref calldata);
        world.execute('create_collection', (calldata));
    }

    {
        let mut calldata: Array<felt252> = ArrayTrait::new();
        CreateCollectionData {
            collection_id: 1,
            params: 2,
            admin_or_system: starknet::contract_address_const::<0xfafa>()
        }.serialize(ref calldata);
        world.execute('create_collection', (calldata));
    }
}
