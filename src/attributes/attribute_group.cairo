use starknet::ContractAddress;

use traits::{Into, TryInto};
use option::OptionTrait;
use clone::Clone;
use serde::Serde;
use zeroable::Zeroable;

use dojo::world::{Context, IWorldDispatcher, IWorldDispatcherTrait};
use briq_protocol::felt_math::{FeltBitAnd, FeltOrd};

use debug::PrintTrait;

impl SerdeLenAttributeGroupOwner of dojo::SerdeLen<AttributeGroupOwner> {
    #[inline(always)]
    fn len() -> usize {
        2
    }
}

impl PrintTraitAttributeGroupOwner of PrintTrait<AttributeGroupOwner> {
    fn print(self: AttributeGroupOwner) {
        match self {
            AttributeGroupOwner::Admin(addr) => addr.print(),
            AttributeGroupOwner::System(system_name) => system_name.print(),
        };
    }
}

#[derive(Copy, Drop, Serde, SerdeLen)]
enum AttributeGroupOwner {
    Admin: ContractAddress,
    System: felt252,
}

#[derive(Component, Copy, Drop, Serde, SerdeLen)]
struct AttributeGroup  {
    #[key]
    attribute_group_id: u64,
    owner: AttributeGroupOwner,
    briq_set_contract_address: ContractAddress
}


trait AttributeGroupTrait {
    fn get_attribute_group(world: IWorldDispatcher, attribute_group_id: u64) -> AttributeGroup ;
    fn set_attribute_group(world: IWorldDispatcher, attribute_group: AttributeGroup );
    fn exists(world: IWorldDispatcher, attribute_group_id: u64) -> bool;

    fn new_attribute_group(
        world: IWorldDispatcher,
        attribute_group_id: u64,
        owner: AttributeGroupOwner,
        briq_set_contract_address: ContractAddress
    ) -> AttributeGroup ;
}

// #[generate_trait]
impl AttributeGroupImpl of AttributeGroupTrait {
    fn get_attribute_group(world: IWorldDispatcher, attribute_group_id: u64) -> AttributeGroup  {
        get!(world, (attribute_group_id), AttributeGroup)
    }

    fn set_attribute_group(world: IWorldDispatcher, attribute_group: AttributeGroup ) {
        set!(world, (attribute_group));
    }

    fn exists(world: IWorldDispatcher, attribute_group_id: u64) -> bool {
        let attribute_group = AttributeGroupTrait::get_attribute_group(world, attribute_group_id);
        attribute_group.briq_set_contract_address.is_non_zero()
    }

    fn new_attribute_group(
        world: IWorldDispatcher,
        attribute_group_id: u64,
        owner: AttributeGroupOwner,
        briq_set_contract_address: ContractAddress
    ) -> AttributeGroup  {
        assert(attribute_group_id > 0, 'invalid attribute_group_id');
        assert(!AttributeGroupTrait::exists(world, attribute_group_id), 'attribute_group already exists');

        AttributeGroup { attribute_group_id: attribute_group_id, owner: owner, briq_set_contract_address }
    }
}


#[derive(Clone, Drop, Serde)]
struct CreateAttributeGroupData {
    attribute_group_id: u64,
    owner: AttributeGroupOwner,
    briq_set_contract_address: ContractAddress
}

#[system]
mod create_attribute_group {
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

    use briq_protocol::attributes::get_attribute_group_id;
    use super::AttributeGroup;

    use debug::PrintTrait;

    use super::{CreateAttributeGroupData, AttributeGroupOwner, AttributeGroupTrait};

    #[derive(Drop, starknet::Event)]
    struct AttributeGroupCreated {
        attribute_group_id: u64,
        owner: ContractAddress,
        system: felt252,
    }

    fn execute(ctx: Context, data: CreateAttributeGroupData) {
        let CreateAttributeGroupData{attribute_group_id, owner, briq_set_contract_address } = data;

        assert(briq_set_contract_address.is_non_zero(), 'Invalid briq_set_contract_addr');

        match owner {
            AttributeGroupOwner::Admin(address) => {
                assert(address.is_non_zero(), 'Must have admin');
            },
            AttributeGroupOwner::System(system_name) => {
                assert(system_name.is_non_zero(), 'Must have admin');
            },
        };

        // TODO: check ctx.origin is actually the origin
        ctx.world.only_admins(@ctx.origin);

        let attribute_group = AttributeGroupTrait::new_attribute_group(
            ctx.world, attribute_group_id, owner, briq_set_contract_address
        );

        AttributeGroupTrait::set_attribute_group(ctx.world, attribute_group);

        match owner {
            AttributeGroupOwner::Admin(address) => {
                emit!(ctx.world, AttributeGroupCreated { attribute_group_id, owner: address, system: '' });
            },
            AttributeGroupOwner::System(system_name) => {
                emit!(
                    ctx.world,
                    AttributeGroupCreated {
                        attribute_group_id, owner: Zeroable::zero(), system: system_name
                    }
                );
            },
        };
    }
}
