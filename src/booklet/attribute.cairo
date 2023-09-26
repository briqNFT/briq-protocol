use starknet::{ContractAddress, ClassHash, get_caller_address};
use array::{ArrayTrait, SpanTrait};
use debug::PrintTrait;

use dojo::world::{IWorldDispatcher, IWorldDispatcherTrait};

use briq_protocol::attributes::attribute_group::{AttributeGroupTrait};

use briq_protocol::world_config::{WorldConfig, AdminTrait, get_world_config};
use briq_protocol::types::{FTSpec, PackedShapeItem};
use briq_protocol::attributes::attributes::IAttributeHandler;

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
    use briq_protocol::world_config::{WorldConfig, AdminTrait};
    use super::{ShapeValidator, RegisterShapeValidatorParams};
    use starknet::get_caller_address;

    fn execute(world: IWorldDispatcher, params: RegisterShapeValidatorParams) {
        world.only_admins(@get_caller_address());

        let RegisterShapeValidatorParams{attribute_group_id, attribute_id, class_hash } = params;
        set!(world, ShapeValidator { attribute_group_id, attribute_id, class_hash });
    }
}

// should panic if check fails, or no validator found
fn assign_check(
    world: IWorldDispatcher,
    set_owner: ContractAddress,
    set_token_id: ContractAddress,
    attribute_group_id: u64,
    attribute_id: u64,
    shape: Span<PackedShapeItem>,
    fts: Span<FTSpec>,
) {
    let shape_validator: ShapeValidator = get!(
        world, (attribute_group_id, attribute_id), ShapeValidator
    );
    if shape_validator.class_hash.is_zero() {
        panic(array!['no shape verifier']);
    }
    IShapeCheckerLibraryDispatcher { class_hash: shape_validator.class_hash }
        .verify_shape(attribute_id, shape, fts);
}

use briq_protocol::erc::get_world::GetWorldTrait;
use briq_protocol::erc::erc1155::internal_trait::InternalTrait1155;

impl BookletAttributeHolder<ContractState,
    impl w: GetWorldTrait<ContractState>,
    impl i: InternalTrait1155<ContractState>,
    impl drop: Drop<ContractState>,
> of IAttributeHandler<ContractState> {
    fn assign(
        ref self: ContractState,
        set_owner: ContractAddress,
        set_token_id: ContractAddress,
        attribute_group_id: u64,
        attribute_id: u64,
        shape: Array<PackedShapeItem>,
        fts: Array<FTSpec>,
    ) {
        // TODO: auth
        let world = self.world();

        assign_check(
            world,
            set_owner,
            set_token_id,
            attribute_group_id,
            attribute_id,
            shape: shape.span(),
            fts: fts.span()
        );

        // Transfer booklet with corresponding attribute_id from set_owner to set_token_id
        self._safe_transfer_from(
            set_owner,
            set_token_id,
            attribute_id.into(),
            1,
            array![],
        );
    }

    fn remove(
        ref self: ContractState,
        set_owner: ContractAddress,
        set_token_id: ContractAddress,
        attribute_group_id: u64,
        attribute_id: u64
    ) {
        // TODO: auth

        // Transfer booklet with corresponding attribute_id from set_token_id to set_owner
        self._safe_transfer_from(
            set_token_id,
            set_owner,
            attribute_id.into(),
            1,
            array![],
        );
    }
}
