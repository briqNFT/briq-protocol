use traits::{Into, TryInto, Default};
use option::{Option, OptionTrait};
use result::ResultTrait;
use array::ArrayTrait;
use serde::Serde;
use starknet::ContractAddress;

use dojo::world::{IWorldDispatcher, IWorldDispatcherTrait};
use briq_protocol::world_config::{WorldConfig, SYSTEM_CONFIG_ID};
use briq_protocol::tests::test_utils::{
    DefaultWorld, DEFAULT_OWNER, USER1, deploy_default_world, impersonate
};

use dojo_erc::erc721::interface::IERC721DispatcherTrait;

use briq_protocol::types::{FTSpec, ShapeItem};

use debug::PrintTrait;

use briq_protocol::attributes::collection::{CreateCollectionData, CollectionOwner};


#[test]
#[available_gas(30000000)]
fn test_create_collections() {
    let DefaultWorld{world, set_nft, .. } = deploy_default_world();

    {
        let mut calldata: Array<felt252> = ArrayTrait::new();
        CreateCollectionData {
            collection_id: 1,
            owner: CollectionOwner::Admin(USER1()),
            briq_set_contract_address: set_nft.contract_address
        }
            .serialize(ref calldata);
        world.execute('create_collection', (calldata));
    }

    {
        let mut calldata: Array<felt252> = ArrayTrait::new();
        CreateCollectionData {
            collection_id: 2,
            owner: CollectionOwner::Admin(USER1()),
            briq_set_contract_address: set_nft.contract_address
        }
            .serialize(ref calldata);
        world.execute('create_collection', (calldata));
    }
}

#[test]
#[available_gas(30000000)]
#[should_panic]
fn test_create_collection_collision() {
    let DefaultWorld{world, set_nft, .. } = deploy_default_world();

    {
        let mut calldata: Array<felt252> = ArrayTrait::new();
        CreateCollectionData {
            collection_id: 1,
            owner: CollectionOwner::Admin(USER1()),
            briq_set_contract_address: set_nft.contract_address
        }
            .serialize(ref calldata);
        world.execute('create_collection', (calldata));
    }

    {
        let mut calldata: Array<felt252> = ArrayTrait::new();
        CreateCollectionData {
            collection_id: 1,
            owner: CollectionOwner::Admin(USER1()),
            briq_set_contract_address: set_nft.contract_address
        }
            .serialize(ref calldata);
        world.execute('create_collection', (calldata));
    }
}


#[test]
#[available_gas(30000000)]
#[should_panic]
fn test_create_collection_with_non_world_admin() {
    let DefaultWorld{world, set_nft, .. } = deploy_default_world();

    impersonate(DEFAULT_OWNER());

    let mut calldata: Array<felt252> = ArrayTrait::new();

    CreateCollectionData {
        collection_id: 1,
        owner: CollectionOwner::Admin(USER1()),
        briq_set_contract_address: set_nft.contract_address
    }
        .serialize(ref calldata);
    world.execute('create_collection', (calldata));
}
