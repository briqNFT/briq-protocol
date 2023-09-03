use starknet::{ContractAddress, ClassHash};
use traits::{Into, TryInto};
use array::{ArrayTrait, SpanTrait};
use option::OptionTrait;
use zeroable::Zeroable;
use clone::Clone;
use serde::Serde;

use dojo::world::{Context, IWorldDispatcher, IWorldDispatcherTrait};
use dojo_erc::erc721::components::{ERC721Balance, ERC721Owner};
use dojo_erc::erc1155::components::ERC1155BalanceTrait;

use briq_protocol::world_config::{AdminTrait, WorldConfig, get_world_config};
use briq_protocol::types::{FTSpec, PackedShapeItem};

use debug::PrintTrait;

impl ClassHashPrint of PrintTrait<ClassHash> {
    fn print(self: ClassHash) {}
}

// AttributeManager is more specific than AttributeGroupManager 
// AttributeManager it takes precedence over AttributeGroupManager

//
// AttributeManager
//

#[derive(Component, Copy, Drop, Serde, SerdeLen)]
struct AttributeManager {
    #[key]
    attribute_group_id: u64,
    #[key]
    attribute_id: u64,
    class_hash: ClassHash,
}

trait AttributeManagerTrait {
    fn assign_attribute(
        self: @AttributeManager,
        world: IWorldDispatcher,
        set_owner: ContractAddress,
        set_token_id: ContractAddress,
        attribute_group_id: u64,
        attribute_id: u64,
        shape: @Array<PackedShapeItem>,
        fts: @Array<FTSpec>,
    );

    fn remove_attribute(
        self: @AttributeManager,
        world: IWorldDispatcher,
        set_owner: ContractAddress,
        set_token_id: ContractAddress,
        attribute_group_id: u64,
        attribute_id: u64,
    );
}


#[derive(Drop, Copy, Serde)]
struct RegisterAttributeManagerParams {
    attribute_group_id: u64,
    attribute_id: u64,
    class_hash: ClassHash,
}

#[system]
mod register_attribute_manager {
    use dojo::world::Context;
    use briq_protocol::world_config::{WorldConfig, AdminTrait};
    use super::{AttributeManager, RegisterAttributeManagerParams};

    fn execute(ctx: Context, params: RegisterAttributeManagerParams) {
        let RegisterAttributeManagerParams{attribute_group_id, attribute_id, class_hash } = params;

        ctx.world.only_admins(@ctx.origin);

        set!(ctx.world, AttributeManager { attribute_group_id, attribute_id, class_hash });
    }
}

//
// AttributeGroupManager
//

#[derive(Component, Copy, Drop, Serde, SerdeLen)]
struct AttributeGroupManager {
    #[key]
    attribute_group_id: u64,
    class_hash: ClassHash,
}

trait AttributeGroupManagerTrait {
    fn assign_attribute(
        self: @AttributeGroupManager,
        world: IWorldDispatcher,
        set_owner: ContractAddress,
        set_token_id: ContractAddress,
        attribute_group_id: u64,
        attribute_id: u64,
        shape: @Array<PackedShapeItem>,
        fts: @Array<FTSpec>,
    );

    fn remove_attribute(
        self: @AttributeGroupManager,
        world: IWorldDispatcher,
        set_owner: ContractAddress,
        set_token_id: ContractAddress,
        attribute_group_id: u64,
        attribute_id: u64,
    );
}


#[derive(Drop, Copy, Serde)]
struct RegisterAttributeGroupManagerParams {
    attribute_group_id: u64,
    class_hash: ClassHash,
}

#[system]
mod register_attr_group_manager {
    use dojo::world::Context;
    use briq_protocol::world_config::{WorldConfig, AdminTrait};
    use super::{AttributeGroupManager, RegisterAttributeGroupManagerParams};

    fn execute(ctx: Context, params: RegisterAttributeGroupManagerParams) {
        let RegisterAttributeGroupManagerParams{attribute_group_id, class_hash } = params;

        ctx.world.only_admins(@ctx.origin);

        set!(ctx.world, AttributeGroupManager { attribute_group_id, class_hash });
    }
}


//
//  Checker Interface
//

#[starknet::interface]
trait IShapeChecker<ContractState> {
    fn verify_shape(
        self: @ContractState, attribute_id: u64, shape: Span<PackedShapeItem>, fts: Span<FTSpec>
    );
}

//
//  Impl Attribute Manager
//

impl AttributeManagerChecker of AttributeManagerTrait {
    fn assign_attribute(
        self: @AttributeManager,
        world: IWorldDispatcher,
        set_owner: ContractAddress,
        set_token_id: ContractAddress,
        attribute_group_id: u64,
        attribute_id: u64,
        shape: @Array<PackedShapeItem>,
        fts: @Array<FTSpec>,
    ) {
        assert((*self.class_hash).is_non_zero(), 'No class hash found');

        IShapeCheckerLibraryDispatcher { class_hash: *self.class_hash }
            .verify_shape(attribute_id, shape.span(), fts.span());
    }

    fn remove_attribute(
        self: @AttributeManager,
        world: IWorldDispatcher,
        set_owner: ContractAddress,
        set_token_id: ContractAddress,
        attribute_group_id: u64,
        attribute_id: u64,
    ) { // do something or not
    }
}


//
// Impl Attribute Group Manager
//

impl AttributeGroupManagerChecker of AttributeGroupManagerTrait {
    fn assign_attribute(
        self: @AttributeGroupManager,
        world: IWorldDispatcher,
        set_owner: ContractAddress,
        set_token_id: ContractAddress,
        attribute_group_id: u64,
        attribute_id: u64,
        shape: @Array<PackedShapeItem>,
        fts: @Array<FTSpec>,
    ) {
        assert((*self.class_hash).is_non_zero(), 'No class hash found');

        IShapeCheckerLibraryDispatcher { class_hash: *self.class_hash }
            .verify_shape(attribute_id, shape.span(), fts.span());
    }

    fn remove_attribute(
        self: @AttributeGroupManager,
        world: IWorldDispatcher,
        set_owner: ContractAddress,
        set_token_id: ContractAddress,
        attribute_group_id: u64,
        attribute_id: u64,
    ) { // do something or not
    }
}


//
// Checker
//

use briq_protocol::attributes::attributes::{
    AttributeHandlerData, AttributeAssignData, AttributeRemoveData,
};

// should panic if check fails, or no manager found
fn assign_check(ctx: Context, data: AttributeAssignData) {
    let AttributeAssignData{set_owner,
    set_token_id,
    attribute_group_id,
    attribute_id,
    shape,
    fts } =
        data;

    let attribute_manager: AttributeManager = get!(
        ctx.world, (attribute_group_id, attribute_id), AttributeManager
    );
    // check if there is an AttributeManager registered
    if (attribute_manager.class_hash.is_non_zero()) {
        attribute_manager
            .assign_attribute(
                ctx.world, set_owner, set_token_id, attribute_group_id, attribute_id, @shape, @fts
            );
    } else {
        let attribute_group_manager: AttributeGroupManager = get!(
            ctx.world, (attribute_group_id), AttributeGroupManager
        );
        // check if there is an AttributeGroupManager registered
        if (attribute_group_manager.class_hash.is_non_zero()) {
            attribute_group_manager
                .assign_attribute(
                    ctx.world,
                    set_owner,
                    set_token_id,
                    attribute_group_id,
                    attribute_id,
                    @shape,
                    @fts
                );
        } else {
            panic(array!['should not happen']);
        }
    }
}


fn remove_check(ctx: Context, data: AttributeRemoveData) {
    let AttributeRemoveData{set_owner, set_token_id, attribute_group_id, attribute_id } = data;
    let attribute_manager: AttributeManager = get!(
        ctx.world, (attribute_group_id, attribute_id), AttributeManager
    );
    // check if there is an AttributeManager registered
    if (attribute_manager.class_hash.is_non_zero()) {
        attribute_manager
            .remove_attribute(ctx.world, set_owner, set_token_id, attribute_group_id, attribute_id);
    } else {
        let attribute_group_manager: AttributeGroupManager = get!(
            ctx.world, (attribute_group_id), AttributeGroupManager
        );
        // check if there is an AttributeGroupManager registered
        if (attribute_group_manager.class_hash.is_non_zero()) {
            attribute_group_manager
                .remove_attribute(
                    ctx.world, set_owner, set_token_id, attribute_group_id, attribute_id,
                );
        }
        else {
            panic(array!['should not happen']);
        }
    }
}

//
// System 
//

#[system]
mod attribute_manager_checker {
    use zeroable::Zeroable;
    use dojo::world::Context;
    use briq_protocol::world_config::{WorldConfig, AdminTrait};
    use briq_protocol::attributes::attributes::{
        AttributeHandlerData, AttributeAssignData, AttributeRemoveData,
    };
    use super::{
        AttributeManager, AttributeManagerTrait, AttributeGroupManager, AttributeGroupManagerTrait,
        AttributeManagerChecker, AttributeGroupManagerChecker, assign_check, remove_check
    };

    fn execute(ctx: Context, data: AttributeHandlerData) {
        match data {
            AttributeHandlerData::Assign(d) => {
                assign_check(ctx, d);
            },
            AttributeHandlerData::Remove(d) => {
                remove_check(ctx, d);
            },
        }
    }
}


#[system]
mod attribute_manager_booklet {
    use zeroable::Zeroable;
    use clone::Clone;
    use traits::Into;
    use array::{ArrayTrait, SpanTrait};
    use dojo::world::Context;
    use dojo_erc::erc1155::components::ERC1155BalanceTrait;
    use briq_protocol::world_config::{WorldConfig, AdminTrait, get_world_config};
    use briq_protocol::attributes::attributes::{
        AttributeHandlerData, AttributeAssignData, AttributeRemoveData,
    };
    use super::{
        AttributeManager, AttributeManagerTrait, AttributeGroupManager, AttributeGroupManagerTrait,
        AttributeManagerChecker, AttributeGroupManagerChecker, assign_check, remove_check
    };

    fn execute(ctx: Context, data: AttributeHandlerData) {
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

                // TODO : use update that sends events
                // Transfer booklet with corresponding attribute_id from set_owner to set_token_id
                ERC1155BalanceTrait::unchecked_transfer_tokens(
                    ctx.world,
                    get_world_config(ctx.world).booklet,
                    set_owner,
                    set_token_id,
                    array![attribute_id.into()].span(),
                    array![1].span()
                );
            },
            AttributeHandlerData::Remove(d) => {
                let AttributeRemoveData{set_owner,
                set_token_id,
                attribute_group_id,
                attribute_id } =
                    d;

                remove_check(
                    ctx,
                    AttributeRemoveData {
                        set_owner, set_token_id, attribute_group_id, attribute_id
                    }
                );

                // TODO : use update that sends events
                // Transfer booklet with corresponding attribute_id from set_token_id to set_owner
                ERC1155BalanceTrait::unchecked_transfer_tokens(
                    ctx.world,
                    get_world_config(ctx.world).booklet,
                    set_token_id,
                    set_owner,
                    array![attribute_id.into()].span(),
                    array![1].span()
                );
            },
        }
    }
}
