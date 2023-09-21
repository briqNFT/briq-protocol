use starknet::{ContractAddress, ClassHash, get_caller_address};
use traits::{Into, TryInto};
use array::{ArrayTrait, SpanTrait};
use option::OptionTrait;
use zeroable::Zeroable;
use clone::Clone;
use serde::Serde;

use dojo::world::{Context, IWorldDispatcher, IWorldDispatcherTrait};
use dojo_erc::erc721::components::{ERC721Balance, ERC721Owner};

use briq_protocol::world_config::{AdminTrait, WorldConfig, get_world_config};
use briq_protocol::types::{FTSpec, PackedShapeItem};

use debug::PrintTrait;

impl ClassHashPrint of PrintTrait<ClassHash> {
    fn print(self: ClassHash) {}
}

#[derive(Component, Copy, Drop, Serde)]
struct ShapeValidator {
    #[key]
    attribute_group_id: u64,
    #[key]
    attribute_id: u64,
    class_hash: ClassHash,
}

// Must be implemented by the class hash pointed to by ShapeValidator
#[starknet::interface]
trait IShapeChecker<ContractState> {
    fn verify_shape(
        self: @ContractState, attribute_id: u64, shape: Span<PackedShapeItem>, fts: Span<FTSpec>
    );
}

#[derive(Drop, Copy, Serde)]
struct RegisterShapeValidatorParams {
    attribute_group_id: u64,
    attribute_id: u64,
    class_hash: ClassHash,
}

#[system]
mod RegisterShapeValidator {
    use dojo::world::Context;
    use briq_protocol::world_config::{WorldConfig, AdminTrait};
    use super::{ShapeValidator, RegisterShapeValidatorParams};

    fn execute(ctx: Context, params: RegisterShapeValidatorParams) {
        ctx.world.only_admins(@ctx.origin);

        let RegisterShapeValidatorParams{attribute_group_id, attribute_id, class_hash } = params;
        set!(ctx.world, ShapeValidator { attribute_group_id, attribute_id, class_hash });
    }
}


#[system]
mod agm_booklet {
    use zeroable::Zeroable;
    use clone::Clone;
    use traits::Into;
    use array::{ArrayTrait, SpanTrait};
    use dojo::world::{Context};
    use dojo_erc::erc1155::systems::unchecked_update;
    use briq_protocol::world_config::{WorldConfig, AdminTrait, get_world_config};
    use briq_protocol::attributes::attributes::{
        AttributeHandlerData, AttributeAssignData, AttributeRemoveData,
    };
    use briq_protocol::attributes::attribute_group::{AttributeGroupTrait};

    use super::{ShapeValidator, IShapeCheckerDispatcherTrait, IShapeCheckerLibraryDispatcher};


    use debug::PrintTrait;

    // should panic if check fails, or no validator found
    fn assign_check(ctx: Context, data: AttributeAssignData) {
        let AttributeAssignData{set_owner,
        set_token_id,
        attribute_group_id,
        attribute_id,
        shape,
        fts } =
            data;

        let shape_validator: ShapeValidator = get!(
            ctx.world, (attribute_group_id, attribute_id), ShapeValidator
        );
        if shape_validator.class_hash.is_zero() {
            panic(array!['no shape verifier']);
        }
        IShapeCheckerLibraryDispatcher { class_hash: shape_validator.class_hash }
            .verify_shape(attribute_id, shape.span(), fts.span());
    }

    fn execute(ctx: Context, data: AttributeHandlerData) {
        // TODO: auth

        match data {
            AttributeHandlerData::Assign(d) => {
                let AttributeAssignData{set_owner,
                set_token_id,
                attribute_group_id,
                attribute_id,
                shape,
                fts } =
                    d;

                assign_check(
                    ctx,
                    AttributeAssignData {
                        set_owner,
                        set_token_id,
                        attribute_group_id,
                        attribute_id,
                        shape: shape.clone(),
                        fts: fts.clone()
                    }
                );

                // find booklet collection related to this attribute group
                let attribute_group = AttributeGroupTrait::get_attribute_group(
                    ctx.world, attribute_group_id
                );
                assert(
                    attribute_group.booklet_contract_address.is_non_zero(),
                    'invalid booklet_address'
                );

                // TODO : use update that sends events
                // Transfer booklet with corresponding attribute_id from set_owner to set_token_id
                unchecked_update(
                    ctx.world,
                    ctx.origin,
                    attribute_group.booklet_contract_address,
                    set_owner,
                    set_token_id,
                    array![attribute_id.into()],
                    array![1],
                    array![],
                );
            },
            AttributeHandlerData::Remove(d) => {
                let AttributeRemoveData{set_owner,
                set_token_id,
                attribute_group_id,
                attribute_id } =
                    d;

                // find booklet collection related to this attribute group
                let attribute_group = AttributeGroupTrait::get_attribute_group(
                    ctx.world, attribute_group_id
                );
                assert(
                    attribute_group.booklet_contract_address.is_non_zero(),
                    'invalid booklet_address'
                );

                // TODO : use update that sends events
                // Transfer booklet with corresponding attribute_id from set_token_id to set_owner
                unchecked_update(
                    ctx.world,
                    ctx.origin,
                    attribute_group.booklet_contract_address,
                    set_token_id,
                    set_owner,
                    array![attribute_id.into()],
                    array![1],
                    array![],
                );
            },
        }
    }
}
