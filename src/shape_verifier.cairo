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
use briq_protocol::world_config::{AdminTrait, WorldConfig, get_world_config};

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

trait ShapeVerifierTrait {
    fn assign_attribute(
        self: @ShapeVerifier,
        world: IWorldDispatcher,
        set_owner: ContractAddress,
        set_token_id: ContractAddress,
        attribute_id: felt252,
        shape: @Array<PackedShapeItem>,
        fts: @Array<FTSpec>,
    );

    fn remove_attribute(
        self: @ShapeVerifier,
        world: IWorldDispatcher,
        set_owner: ContractAddress,
        set_token_id: ContractAddress,
        attribute_id: felt252,
    );
}

impl ShapeVerifierImpl of ShapeVerifierTrait {
    fn assign_attribute(
        self: @ShapeVerifier,
        world: IWorldDispatcher,
        set_owner: ContractAddress,
        set_token_id: ContractAddress,
        attribute_id: felt252,
        shape: @Array<PackedShapeItem>,
        fts: @Array<FTSpec>,
    ) {
        assert((*self.class_hash).is_non_zero(), 'No class hash found');

        IShapeCheckerLibraryDispatcher { class_hash: *self.class_hash }
            .verify_shape(attribute_id, shape.span(), fts.span());

        // TODO -> use update that sends events
        dojo_erc::erc1155::components::ERC1155BalanceTrait::unchecked_transfer_tokens(
            world,
            get_world_config(world).booklet,
            set_owner,
            set_token_id,
            array![attribute_id].span(),
            array![1].span()
        );
    }

    fn remove_attribute(
        self: @ShapeVerifier,
        world: IWorldDispatcher,
        set_owner: ContractAddress,
        set_token_id: ContractAddress,
        attribute_id: felt252,
    ) {
        // TODO -> use update that sends events
        dojo_erc::erc1155::components::ERC1155BalanceTrait::unchecked_transfer_tokens(
            world,
            get_world_config(world).booklet,
            set_token_id,
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

    use briq_protocol::world_config::{WorldConfig, AdminTrait};

    fn execute(ctx: Context, data: RegisterShapeVerifierData,) {
        let RegisterShapeVerifierData{attribute_id, class_hash } = data;

        ctx.world.only_admins(@ctx.origin);

        set!(ctx.world, ShapeVerifier { attribute_id, class_hash });
    }
}

#[system]
mod shape_verifier_system {
    use dojo::world::Context;
    use briq_protocol::world_config::{WorldConfig, AdminTrait};

    use super::{ShapeVerifier, ShapeVerifierTrait};
    use briq_protocol::attributes::attributes::{
        AttributeHandlerData, AttributeAssignData, AttributeRemoveData,
    };

    fn execute(ctx: Context, data: AttributeHandlerData) {
        match data {
            AttributeHandlerData::Assign(d) => {
                let AttributeAssignData{set_owner, set_token_id, attribute_id, shape, fts } = d;
                let shape_verifier = get!(ctx.world, (attribute_id), ShapeVerifier);
                shape_verifier
                    .assign_attribute(
                        ctx.world, set_owner, set_token_id, attribute_id, @shape, @fts
                    );
            },
            AttributeHandlerData::Remove(d) => {
                let AttributeRemoveData{set_owner, set_token_id, attribute_id } = d;
                let shape_verifier = get!(ctx.world, (attribute_id), ShapeVerifier);
                shape_verifier.remove_attribute(ctx.world, set_owner, set_token_id, attribute_id);
            },
        }
    }
}
