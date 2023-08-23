use starknet::{ContractAddress, ClassHash};
use traits::Into;
use traits::TryInto;
use array::ArrayTrait;
use array::SpanTrait;
use option::OptionTrait;
use zeroable::Zeroable;
use clone::Clone;
use serde::Serde;

use dojo::world::{Context, IWorldDispatcher, IWorldDispatcherTrait};
use dojo_erc::erc721::components::{ERC721Balance, ERC721Owner};
use briq_protocol::world_config::{SYSTEM_CONFIG_ID, WorldConfig};

use briq_protocol::types::{FTSpec, PackedShapeItem};

use debug::PrintTrait;


#[starknet::interface]
trait IShapeChecker<ContractState> {
    fn verify_shape(
        self: @ContractState, token_id: felt252, shape: Span<PackedShapeItem>, fts: Span<FTSpec>
    );
}

impl ClassHashPrint of PrintTrait<ClassHash> {
    fn print(self: ClassHash) {}
}

#[derive(Component, Copy, Drop, Serde, SerdeLen)]
struct ShapeVerifier {
    #[key]
    attribute_id: u64,
    class_hash: ClassHash,
}

trait CheckShapeTrait {
    fn assign_attribute(
        self: @ShapeVerifier,
        world: IWorldDispatcher,
        set_owner: ContractAddress,
        set_token_id: felt252,
        attribute_id: felt252,
        shape: @Array<PackedShapeItem>,
        fts: @Array<FTSpec>,
    );

    fn remove_attribute(
        self: @ShapeVerifier,
        world: IWorldDispatcher,
        set_owner: ContractAddress,
        set_token_id: felt252,
        attribute_id: felt252,
    );

    fn check_shape(
        self: @ShapeVerifier, attribute_id: felt252, shape: @Array<PackedShapeItem>, fts: @Array<FTSpec>, 
    );
}

impl CheckShapeImpl of CheckShapeTrait {
    fn assign_attribute(
        self: @ShapeVerifier,
        world: IWorldDispatcher,
        set_owner: ContractAddress,
        set_token_id: felt252,
        attribute_id: felt252,
        shape: @Array<PackedShapeItem>,
        fts: @Array<FTSpec>,
    ) {
        // 3 things to do:
        //  - check that we're being called by the proper system
        //  - check that the shape is valid
        //  - try to transfer the booklet (also checks ownership)

        // TODO
        //assert(ctx.world.caller_system()? == 'assign_attributes', 'Bad system caller');

        self.check_shape(attribute_id, shape, fts);

        // TODO -> use update that sends events
        dojo_erc::erc1155::components::ERC1155BalanceTrait::transfer_tokens(
            world,
            get!(world, (SYSTEM_CONFIG_ID), WorldConfig).booklet,
            set_owner,
            set_token_id.try_into().unwrap(),
            array![attribute_id].span(),
            array![1].span()
        );
    }

    fn check_shape(
        self: @ShapeVerifier, attribute_id: felt252, shape: @Array<PackedShapeItem>, fts: @Array<FTSpec>, 
    ) {
        assert((*self.class_hash).is_non_zero(), 'No class hash found');

        IShapeCheckerLibraryDispatcher {
            class_hash: *self.class_hash
        }.verify_shape(attribute_id, shape.span(), fts.span());

        return ();
    }

    fn remove_attribute(
        self: @ShapeVerifier,
        world: IWorldDispatcher,
        set_owner: ContractAddress,
        set_token_id: felt252,
        attribute_id: felt252,
    ) {
        // TODO: check that we're being called by the proper system

        // TODO -> use update that sends events
        dojo_erc::erc1155::components::ERC1155BalanceTrait::transfer_tokens(
            world,
            get!(world, (SYSTEM_CONFIG_ID), WorldConfig).booklet,
            set_token_id.try_into().unwrap(),
            set_owner,
            array![attribute_id].span(),
            array![1].span()
        );
    }
}

#[derive(Drop, Copy, Serde)]
struct RegisterShapeVerifierData {
    attribute_id: u64,
    class_hash: ClassHash,
}

#[system]
mod register_shape_verifier {
    use dojo::world::Context;
    use super::RegisterShapeVerifierData;
    use super::ShapeVerifier;

    use briq_protocol::world_config::{SYSTEM_CONFIG_ID, WorldConfig, AdminTrait};

    fn execute(ctx: Context, data: RegisterShapeVerifierData, ) {
        let RegisterShapeVerifierData{attribute_id, class_hash } = data;

        ctx.world.only_admins(@ctx.origin);

        set!(ctx.world, ShapeVerifier { attribute_id, class_hash });
    }
}

#[system]
mod verify_shape {
    use dojo::world::Context;
    use super::{ShapeVerifier, CheckShapeTrait};
    use briq_protocol::attributes::attributes::AttributeAssignData;

    use briq_protocol::world_config::{SYSTEM_CONFIG_ID, WorldConfig, AdminTrait};

    fn execute(ctx: Context, data: AttributeAssignData) {
        let AttributeAssignData { set_owner, set_token_id, attribute_id, shape, fts } = data;
        let shape_verifier = get!(ctx.world, (attribute_id), ShapeVerifier);
        shape_verifier
            .assign_attribute(ctx.world, set_owner, set_token_id, attribute_id, @shape, @fts);
    }
}
