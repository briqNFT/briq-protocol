use starknet::ContractAddress;

const EXISTS_BIT: felt252 = 1; // This bit is always toggled for a collection that exists.
const CONTRACT_BIT: felt252 = 2;

use traits::{Into, TryInto};
use option::OptionTrait;
use clone::Clone;
use serde::Serde;

use briq_protocol::felt_math::{feltBitAnd, feltOrd};

#[derive(Component, Copy, Drop, Serde, SerdeLen)]
struct Collection {
    #[key]
    collection_id: u64,

    parameters: felt252, // bitfield
    admin_or_system: ContractAddress,
}

#[generate_trait]
impl CollectionImpl of CollectionTrait {
    fn get_admin_or_system(self: @Collection) -> (Option<ContractAddress>, Option<ContractAddress>) {
        let a_o_c = self.admin_or_system;
        if *self.parameters & CONTRACT_BIT == 0 {
            return (Option::Some(*a_o_c), Option::None);
        } else {
            return (Option::None, Option::Some(*a_o_c));
        }
    }
}

fn new_collection(collection_id: u64, params: felt252, admin_or_system: ContractAddress) -> Collection {
    let existence_bit_toggled = params & EXISTS_BIT;
    // Probably indicates an error, fail.
    assert(existence_bit_toggled == 0, 'Invalid bits');
    assert(params < 0x400000000000000000000000000000000000000000000000000000000000000, 'Invalid bits');
    
    Collection {
        collection_id: collection_id,
        parameters: params + EXISTS_BIT,
        admin_or_system: admin_or_system,
    }
}

#[derive(Clone, Drop, Serde)]
struct CreateCollectionData
{
    collection_id: u64,
    params: felt252,
    admin_or_system: ContractAddress
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
    use briq_protocol::attributes::collection::{Collection, CollectionTrait, new_collection};

    use debug::PrintTrait;

    use super::CreateCollectionData;

    #[derive(Drop, starknet::Event)]
    struct CollectionCreated {
        collection_id: u64,
        system: ContractAddress,
        admin: ContractAddress,
        parameters: felt252
    }

    fn execute(
        ctx: Context,
        data: CreateCollectionData,
    ) {
        let CreateCollectionData { collection_id, params, admin_or_system } = data;

        assert(admin_or_system.is_non_zero(), 'Must have admin');

        // TODO: check ctx.origin is actually the origin
        ctx.world.only_admins(@ctx.origin);

        assert(get!(ctx.world, (collection_id), Collection).parameters == 0, 'Collec already exists');

        let collec = new_collection(collection_id, params, admin_or_system);
    
        set!(ctx.world, (collec));

        let (admin, system) = collec.get_admin_or_system();
        if admin.is_some() {
            emit!(ctx.world, CollectionCreated { collection_id, system: Zeroable::zero(), admin: admin.unwrap(), parameters:params });
        } else {
            emit!(ctx.world, CollectionCreated { collection_id, system: system.unwrap(), admin: Zeroable::zero(), parameters:params });
        }
    }
}
