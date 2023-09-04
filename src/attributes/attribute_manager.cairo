use starknet::{ContractAddress, ClassHash, get_caller_address};
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
        ctx.world.only_admins(@ctx.origin);

        let RegisterAttributeManagerParams{attribute_group_id, attribute_id, class_hash } = params;
        set!(ctx.world, AttributeManager { attribute_group_id, attribute_id, class_hash });
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

impl AttributeManagerImpl of AttributeManagerTrait {
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
// Auth Checker for group_systems
//

fn assert_valid_caller(ctx: Context) {
    // TODO : update when we can retrieve 'real' caller_system from world
    // actual caller_system returns current system
    // ctx.world.caller_system().print();
    // assert(
    //     ctx.world.caller_system() == 'set_nft_assembly' || ctx.system == 'set_nft_disassembly',
    //     'invalid caller system'
    // );
    
    assert(get_caller_address() == ctx.world.contract_address, 'invalid caller');
}

