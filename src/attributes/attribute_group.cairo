use starknet::ContractAddress;
use traits::{Into, TryInto};
use option::OptionTrait;
use clone::Clone;
use serde::Serde;
use zeroable::Zeroable;

use dojo::world::{Context, IWorldDispatcher, IWorldDispatcherTrait};
use dojo::database::schema::{EnumMember, Member, Ty, Struct, SchemaIntrospection, serialize_member, serialize_member_type};

use briq_protocol::felt_math::{FeltBitAnd, FeltOrd};

use debug::PrintTrait;

impl SerdeLenAttributeGroupOwner of SchemaIntrospection<AttributeGroupOwner> {
    #[inline(always)]
    fn size() -> usize {
        2
    }

    fn layout(ref layout: Array<u8>) {
        layout.append(8);
        layout.append(251);
    }

    #[inline(always)]
    fn ty() -> Ty {
        Ty::Enum(EnumMember{
            name: 'AttributeGroupOwner',
            attrs: array![].span(),
            values: array![
                serialize_member_type(@Ty::Simple('Admin')),
                serialize_member_type(@Ty::Simple('System')),
            ].span()
        })
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

#[derive(Copy, Drop, Serde)]
enum AttributeGroupOwner {
    Admin: ContractAddress,
    System: felt252,
}

#[derive(Component, Copy, Drop, Serde)]
struct AttributeGroup {
    #[key]
    attribute_group_id: u64,
    owner: AttributeGroupOwner,
    target_set_contract_address: ContractAddress,
    booklet_contract_address: ContractAddress,
}


trait AttributeGroupTrait {
    fn get_attribute_group(world: IWorldDispatcher, attribute_group_id: u64) -> AttributeGroup;
    fn set_attribute_group(world: IWorldDispatcher, attribute_group: AttributeGroup);
    fn exists(world: IWorldDispatcher, attribute_group_id: u64) -> bool;

    fn new_attribute_group(
        world: IWorldDispatcher,
        attribute_group_id: u64,
        owner: AttributeGroupOwner,
        target_set_contract_address: ContractAddress,
        booklet_contract_address: ContractAddress,
    ) -> AttributeGroup;
}

// #[generate_trait]
impl AttributeGroupImpl of AttributeGroupTrait {
    fn get_attribute_group(world: IWorldDispatcher, attribute_group_id: u64) -> AttributeGroup {
        get!(world, (attribute_group_id), AttributeGroup)
    }

    fn set_attribute_group(world: IWorldDispatcher, attribute_group: AttributeGroup) {
        set!(world, (attribute_group));
    }

    fn exists(world: IWorldDispatcher, attribute_group_id: u64) -> bool {
        let attribute_group = AttributeGroupTrait::get_attribute_group(world, attribute_group_id);
        attribute_group.target_set_contract_address.is_non_zero()
    }

    fn new_attribute_group(
        world: IWorldDispatcher,
        attribute_group_id: u64,
        owner: AttributeGroupOwner,
        target_set_contract_address: ContractAddress,
        booklet_contract_address: ContractAddress,
    ) -> AttributeGroup {
        assert(attribute_group_id > 0, 'invalid attribute_group_id');
        assert(
            !AttributeGroupTrait::exists(world, attribute_group_id),
            'attribute_group already exists'
        );

        AttributeGroup {
            attribute_group_id: attribute_group_id,
            owner: owner,
            target_set_contract_address,
            booklet_contract_address
        }
    }
}

#[derive(Drop, PartialEq, starknet::Event)]
struct AttributeGroupCreated {
    attribute_group_id: u64,
    owner: ContractAddress,
    system: felt252,
}

#[derive(Drop, PartialEq, starknet::Event)]
struct AttributeGroupUpdated {
    attribute_group_id: u64,
    owner: ContractAddress,
    system: felt252,
}

#[event]
#[derive(Drop, PartialEq, starknet::Event)]
enum Event {
    AttributeGroupCreated: AttributeGroupCreated,
    AttributeGroupUpdated: AttributeGroupUpdated,
}

#[derive(Clone, Drop, Serde)]
struct CreateAttributeGroupParams {
    attribute_group_id: u64,
    owner: AttributeGroupOwner,
    target_set_contract_address: ContractAddress,
    booklet_contract_address: ContractAddress,
}

#[system]
mod create_attribute_group {
    use starknet::ContractAddress;
    use traits::{Into, TryInto};
    use array::{ArrayTrait, SpanTrait};
    use option::OptionTrait;
    use zeroable::Zeroable;
    use clone::Clone;
    use serde::Serde;

    use dojo::world::Context;
    use dojo_erc::erc1155::components::ERC1155Balance;

    use briq_protocol::world_config::AdminTrait;
    use briq_protocol::types::{FTSpec, ShapeItem};

    use debug::PrintTrait;

    use super::{
        CreateAttributeGroupParams, AttributeGroupOwner, AttributeGroupTrait, AttributeGroup
    };

    use super::{AttributeGroupCreated};
    #[event]
    use super::Event;

    fn execute(ctx: Context, data: CreateAttributeGroupParams) {
        ctx.world.only_admins(@ctx.origin);

        let CreateAttributeGroupParams{attribute_group_id,
        owner,
        target_set_contract_address,
        booklet_contract_address } =
            data;

        assert(target_set_contract_address.is_non_zero(), 'Invalid target_contract_address');

        match owner {
            AttributeGroupOwner::Admin(address) => {
                assert(address.is_non_zero(), 'Must have admin');
            },
            AttributeGroupOwner::System(system_name) => {
                assert(system_name.is_non_zero(), 'Must have admin');
            },
        };

        let attribute_group = AttributeGroupTrait::new_attribute_group(
            ctx.world,
            attribute_group_id,
            owner,
            target_set_contract_address,
            booklet_contract_address
        );

        AttributeGroupTrait::set_attribute_group(ctx.world, attribute_group);

        match owner {
            AttributeGroupOwner::Admin(address) => {
                emit!(
                    ctx.world,
                    AttributeGroupCreated { attribute_group_id, owner: address, system: '' }
                );
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


#[derive(Clone, Drop, Serde)]
struct UpdateAttributeGroupParams {
    attribute_group_id: u64,
    owner: AttributeGroupOwner,
    target_set_contract_address: ContractAddress,
    booklet_contract_address: ContractAddress,
}

#[system]
mod update_attribute_group {
    use starknet::ContractAddress;
    use traits::{Into, TryInto};
    use array::{ArrayTrait, SpanTrait};
    use option::OptionTrait;
    use zeroable::Zeroable;
    use clone::Clone;
    use serde::Serde;

    use dojo::world::Context;
    use dojo_erc::erc1155::components::ERC1155Balance;

    use briq_protocol::world_config::AdminTrait;
    use briq_protocol::types::{FTSpec, ShapeItem};

    use debug::PrintTrait;

    use super::{
        UpdateAttributeGroupParams, AttributeGroupOwner, AttributeGroupTrait, AttributeGroup
    };

    use super::{AttributeGroupUpdated};
    #[event]
    use super::Event;

    fn execute(ctx: Context, data: UpdateAttributeGroupParams) {
        ctx.world.only_admins(@ctx.origin);

        let UpdateAttributeGroupParams{attribute_group_id,
        owner,
        target_set_contract_address,
        booklet_contract_address } =
            data;
        assert(target_set_contract_address.is_non_zero(), 'Invalid target_contract_address');

        match owner {
            AttributeGroupOwner::Admin(address) => {
                assert(address.is_non_zero(), 'Must have admin');
            },
            AttributeGroupOwner::System(system_name) => {
                assert(system_name.is_non_zero(), 'Must have admin');
            },
        };

        // check that attribute group already exists
        assert(
            AttributeGroupTrait::exists(ctx.world, attribute_group_id),
            'unexisting attribute_group_id'
        );

        // update attribute_group
        AttributeGroupTrait::set_attribute_group(
            ctx.world,
            AttributeGroup {
                attribute_group_id, owner, target_set_contract_address, booklet_contract_address
            }
        );

        match owner {
            AttributeGroupOwner::Admin(address) => {
                emit!(
                    ctx.world,
                    AttributeGroupUpdated { attribute_group_id, owner: address, system: '' }
                );
            },
            AttributeGroupOwner::System(system_name) => {
                emit!(
                    ctx.world,
                    AttributeGroupUpdated {
                        attribute_group_id, owner: Zeroable::zero(), system: system_name
                    }
                );
            },
        };
    }
}
