use starknet::ContractAddress;

const EXISTS_BIT: felt252 = 1; // This bit is always toggled for a collection that exists.
const CONTRACT_BIT: felt252 = 2;

use traits::{Into, TryInto};
use option::OptionTrait;
use clone::Clone;
use serde::Serde;
use zeroable::Zeroable;

use dojo::world::{Context, IWorldDispatcher, IWorldDispatcherTrait};
use briq_protocol::felt_math::{FeltBitAnd, FeltOrd};

use debug::PrintTrait;

impl SerdeLenCollectionOwner of dojo::SerdeLen<CollectionOwner> {
    #[inline(always)]
    fn len() -> usize {
        2
    }
}

impl PrintTraitCollectionOwner of PrintTrait<CollectionOwner> {
    fn print(self: CollectionOwner) {
        match self {
            CollectionOwner::Admin(addr) => addr.print(),
            CollectionOwner::System(system_name) => system_name.print(),
        };
    }
}

#[derive(Copy, Drop, Serde, SerdeLen)]
enum CollectionOwner {
    Admin: ContractAddress,
    System: felt252,
}

#[derive(Component, Copy, Drop, Serde, SerdeLen)]
struct Collection {
    #[key]
    collection_id: u64,
    owner: CollectionOwner,
    briq_set_contract_address: ContractAddress
}


trait CollectionTrait {
    fn get_collection(world: IWorldDispatcher, collection_id: u64) -> Collection;
    fn set_collection(world: IWorldDispatcher, collection: Collection);
    fn exists(world: IWorldDispatcher, collection_id: u64) -> bool;

    fn new_collection(
        world: IWorldDispatcher,
        collection_id: u64,
        owner: CollectionOwner,
        briq_set_contract_address: ContractAddress
    ) -> Collection;
}

// #[generate_trait]
impl CollectionImpl of CollectionTrait {
    fn get_collection(world: IWorldDispatcher, collection_id: u64) -> Collection {
        get!(world, (collection_id), Collection)
    }

    fn set_collection(world: IWorldDispatcher, collection: Collection) {
        set!(world, (collection));
    }

    fn exists(world: IWorldDispatcher, collection_id: u64) -> bool {
        let collection = CollectionTrait::get_collection(world, collection_id);
        collection.briq_set_contract_address.is_non_zero()
    }

    fn new_collection(
        world: IWorldDispatcher,
        collection_id: u64,
        owner: CollectionOwner,
        briq_set_contract_address: ContractAddress
    ) -> Collection {
        assert(collection_id > 0, 'invalid collection_id');
        assert(!CollectionTrait::exists(world, collection_id), 'collection already exists');

        Collection { collection_id: collection_id, owner: owner, briq_set_contract_address }
    }
}


#[derive(Clone, Drop, Serde)]
struct CreateCollectionData {
    collection_id: u64,
    owner: CollectionOwner,
    briq_set_contract_address: ContractAddress
}

#[system]
mod create_collection {
    use starknet::ContractAddress;
    use traits::Into;
    use traits::TryInto;
    use array::ArrayTrait;
    use array::SpanTrait;
    use option::OptionTrait;
    use zeroable::Zeroable;
    use clone::Clone;
    use serde::Serde;

    use dojo::world::Context;
    use dojo_erc::erc1155::components::ERC1155Balance;
    use briq_protocol::world_config::AdminTrait;

    use briq_protocol::types::{FTSpec, ShapeItem};

    use briq_protocol::attributes::get_collection_id;
    use briq_protocol::attributes::collection::{Collection};

    use debug::PrintTrait;

    use super::{CreateCollectionData, CollectionOwner, CollectionTrait};

    #[derive(Drop, starknet::Event)]
    struct CollectionCreated {
        collection_id: u64,
        owner: ContractAddress,
        system: felt252,
    }

    fn execute(ctx: Context, data: CreateCollectionData) {
        let CreateCollectionData{collection_id, owner, briq_set_contract_address } = data;

        assert(briq_set_contract_address.is_non_zero(), 'Invalid briq_set_contract_addr');

        match owner {
            CollectionOwner::Admin(address) => {
                assert(address.is_non_zero(), 'Must have admin');
            },
            CollectionOwner::System(system_name) => {
                assert(system_name.is_non_zero(), 'Must have admin');
            },
        };

        // TODO: check ctx.origin is actually the origin
        ctx.world.only_admins(@ctx.origin);

        let collection = CollectionTrait::get_collection(ctx.world, collection_id);

        let collec = CollectionTrait::new_collection(
            ctx.world, collection_id, owner, briq_set_contract_address
        );

        CollectionTrait::set_collection(ctx.world, collec);

        match owner {
            CollectionOwner::Admin(address) => {
                emit!(ctx.world, CollectionCreated { collection_id, owner: address, system: '' });
            },
            CollectionOwner::System(system_name) => {
                emit!(
                    ctx.world,
                    CollectionCreated {
                        collection_id, owner: Zeroable::zero(), system: system_name
                    }
                );
            },
        };
    }
}
