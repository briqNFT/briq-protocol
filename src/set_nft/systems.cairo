use starknet::ContractAddress;
use traits::{Into, TryInto};
use array::ArrayTrait;
use array::SpanTrait;
use option::{Option, OptionTrait};
use zeroable::Zeroable;

use dojo::world::Context;

use dojo::world::{IWorldDispatcher, IWorldDispatcherTrait};
use briq_protocol::world_config::{WorldConfig, get_world_config};
use briq_protocol::cumulative_balance::{CUM_BALANCE_TOKEN, CB_BRIQ, CB_ATTRIBUTES};

use dojo_erc::erc1155::components::OperatorApproval;
use dojo_erc::erc1155::components::{ERC1155Balance, ERC1155BalanceTrait};
use dojo_erc::erc1155::interface::{IERC1155DispatcherTrait, IERC1155Dispatcher};

use dojo_erc::erc721::components::{
    ERC721Balance, ERC721BalanceTrait, ERC721Owner, ERC721OwnerTrait, ERC721TokenApproval,
    ERC721TokenApprovalTrait
};

use briq_protocol::attributes::attributes::remove_attributes;
use briq_protocol::types::{FTSpec, PackedShapeItem};
use briq_protocol::utils::IntoContractAddressU256;
use briq_protocol::felt_math::FeltBitAnd;


//###########
//###########
// Assembly/Disassembly

fn transfer_briqs(
    world: IWorldDispatcher,
    sender: ContractAddress,
    recipient: ContractAddress,
    mut fts: Array<FTSpec>
) {
    let address = get_world_config(world).briq;

    loop {
        match fts.pop_front() {
            Option::Some(ftspec) => {
                briq_protocol::briq_token::systems::update_nocheck(
                    world,
                    'set_contract_TODO'.try_into().unwrap(),
                    address,
                    sender,
                    recipient,
                    array![ftspec.token_id],
                    array![ftspec.qty],
                    array![]
                );
            },
            Option::None => {
                break;
            }
        };
    }
}



// To prevent people from generating collisions, we need the token_id to be random.
// However, we need it to be predictable for good UI.
// The solution adopted is to hash a hint. Our security becomes the chain hash security.
// Hash on the # of briqs to avoid people being able to 'game' off-chain latency,
// we had issues where people regenerated sets with the wrong # of briqs shown on marketplaces before a refresh.
fn get_token_id(owner: ContractAddress, token_id_hint: felt252, nb_briqs: u32,) -> ContractAddress {
    let hash = pedersen(0, owner.into());
    let hash = pedersen(hash, token_id_hint);
    let hash = pedersen(hash, nb_briqs.into());

    hash.try_into().unwrap()
}

fn create_token(ctx: Context, recipient: ContractAddress, token_id: felt252) {
    // TODO: retrieve related collection

    let token = get_world_config(ctx.world).set;
    assert(recipient.is_non_zero(), 'ERC721: mint to 0');

    let token_owner = ERC721OwnerTrait::owner_of(ctx.world, token, token_id);
    assert(token_owner.is_zero(), 'ERC721: already minted');

    // increase token supply
    ERC721BalanceTrait::unchecked_increase_balance(ctx.world, token, recipient, 1);
    ERC721OwnerTrait::unchecked_set_owner(ctx.world, token, token_id, recipient);
}

fn destroy_token(ctx: Context, owner: ContractAddress, token_id: ContractAddress) {
    // TODO: retrieve related collection
    let token = get_world_config(ctx.world).set;

    // decrease token supply
    ERC721BalanceTrait::unchecked_decrease_balance(ctx.world, token, owner, 1);
    ERC721OwnerTrait::unchecked_set_owner(ctx.world, token, token_id.into(), Zeroable::zero());
}

fn check_briqs_and_attributes_are_zero(ctx: Context, token_id: ContractAddress) {
    // Check that we gave back all briqs (the user might attempt to lie).

    let balance = ERC1155BalanceTrait::balance_of(
        ctx.world, CUM_BALANCE_TOKEN(), token_id, CB_BRIQ()
    );

    assert(balance == 0, 'Set still has briqs');

    // Check that we no longer have any attributes active.

    let balance = ERC1155BalanceTrait::balance_of(
        ctx.world, CUM_BALANCE_TOKEN(), token_id, CB_ATTRIBUTES()
    );

    assert(balance == 0, 'Set still attributed');
}

#[derive(Drop, Serde)]
struct AssemblySystemData {
    caller: ContractAddress,
    owner: ContractAddress,
    token_id_hint: felt252,
    fts: Array<FTSpec>,
    shape: Array<PackedShapeItem>,
    attributes: Array<felt252>
}

#[system]
mod set_nft_assembly {
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
    use briq_protocol::world_config::{WorldConfig};

    use briq_protocol::types::{FTSpec, PackedShapeItem};

    use briq_protocol::attributes::attributes::assign_attributes;

    use debug::PrintTrait;
    use super::AssemblySystemData;

    fn execute(ctx: Context, data: AssemblySystemData) {
        let AssemblySystemData{caller, owner, token_id_hint, fts, shape, attributes } = data;

        assert(ctx.origin == caller, 'Only Caller');

        assert(shape.len() != 0, 'Cannot mint empty set');

        let token_id = super::get_token_id(owner, token_id_hint, shape.len());
        super::create_token(ctx, owner, token_id.into());
        super::transfer_briqs(ctx.world, owner, token_id, fts.clone());

        if attributes.len() == 0 {
            return;
        }

        assign_attributes(ctx, owner, token_id, attributes, @shape, @fts,);
    }
}


#[derive(Drop, Serde)]
struct DisassemblySystemData {
    caller: ContractAddress,
    owner: ContractAddress,
    token_id: ContractAddress,
    fts: Array<FTSpec>,
    attributes: Array<felt252>
}


#[system]
mod set_nft_disassembly {
    use starknet::ContractAddress;
    use traits::{TryInto, Into};
    use option::OptionTrait;
    use zeroable::Zeroable;
    use clone::Clone;

    use dojo::world::Context;
    use dojo_erc::erc721::components::{
        ERC721Owner, ERC721OwnerTrait, ERC721TokenApproval, ERC721TokenApprovalTrait
    };
    use dojo_erc::erc1155::components::{OperatorApproval, OperatorApprovalTrait};
    use briq_protocol::world_config::{WorldConfig, get_world_config};

    use briq_protocol::types::{FTSpec, PackedShapeItem};

    use briq_protocol::attributes::attributes::remove_attributes;

    use super::DisassemblySystemData;

    fn execute(ctx: Context, data: DisassemblySystemData) {
        let DisassemblySystemData{caller, owner, token_id, fts, attributes } = data;

        assert(ctx.origin == caller, 'Only Caller');

        let token = get_world_config(ctx.world).set;

        let token_owner = ERC721OwnerTrait::owner_of(ctx.world, token, token_id.into());
        assert(token_owner.is_non_zero(), 'ERC721: invalid token_id');
        assert(token_owner == owner, 'SetNft: invalid owner');

        let token_approval = ERC721TokenApprovalTrait::get_approved(
            ctx.world, token, token_id.into()
        );
        let is_approved_for_all = OperatorApprovalTrait::is_approved_for_all(
            ctx.world, token, token_owner, caller
        );

        assert(
            token_owner == caller || is_approved_for_all || token_approval == caller,
            'ERC721: unauthorized caller'
        );

        remove_attributes(ctx, owner, token_id, attributes.clone(),);

        super::transfer_briqs(ctx.world, token_id, owner, fts.clone());

        super::check_briqs_and_attributes_are_zero(ctx, token_id);

        super::destroy_token(ctx, owner, token_id);
    }
}
