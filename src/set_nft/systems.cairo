use starknet::ContractAddress;
use traits::Into;
use traits::TryInto;
use array::ArrayTrait;
use array::SpanTrait;
use option::OptionTrait;
use zeroable::Zeroable;

use debug::PrintTrait;

use dojo::world::Context;

use dojo::world::{IWorldDispatcher, IWorldDispatcherTrait};
use briq_protocol::world_config::{SYSTEM_CONFIG_ID, WorldConfig, get_world_config};
use briq_protocol::cumulative_balance::{CUM_BALANCE_TOKEN, CB_BRIQ, CB_ATTRIBUTES};

use dojo_erc::erc1155::components::OperatorApproval;
use dojo_erc::erc721::components::{ERC721Balance, ERC721Owner, ERC721TokenApproval};
use dojo_erc::erc1155::components::ERC1155Balance;
use dojo_erc::erc1155::interface::{IERC1155DispatcherTrait, IERC1155Dispatcher};

use briq_protocol::attributes::attributes::remove_attributes;

use briq_protocol::types::{FTSpec, PackedShapeItem};

//###########
//###########
// Assembly/Disassembly

fn transfer_briqs(
    world: IWorldDispatcher,
    sender: ContractAddress,
    recipient: ContractAddress,
    mut fts: Array<FTSpec>
) {
    if fts.len() == 0 {
        return ();
    }
    let address = get!(world, (SYSTEM_CONFIG_ID), WorldConfig).briq;
    let ftspec = fts.pop_front().unwrap();

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

    return transfer_briqs(world, sender, recipient, fts);
}

// To prevent people from generating collisions, we need the token_id to be random.
// However, we need it to be predictable for good UI.
// The solution adopted is to hash a hint. Our security becomes the chain hash security.
// Hash on the # of briqs to avoid people being able to 'game' off-chain latency,
// we had issues where people regenerated sets with the wrong # of briqs shown on marketplaces before a refresh.
fn hash_token_id(owner: ContractAddress, token_id_hint: felt252, nb_briqs: u32,) -> felt252 {
    let hash = pedersen(0, owner.into());
    let hash = pedersen(hash, token_id_hint);
    let hash = pedersen(hash, nb_briqs.into());
    hash
}

fn create_token(ctx: Context, recipient: ContractAddress, token_id: felt252) {
    let token = get_world_config(ctx.world).set;
    assert(recipient.is_non_zero(), 'ERC721: mint to 0');

    let token_owner = get!(ctx.world, (token, token_id), ERC721Owner);
    assert(token_owner.address.is_zero(), 'ERC721: already minted');

    // increase token supply
    let mut balance = get!(ctx.world, (token, recipient), ERC721Balance);
    balance.amount += 1;
    set!(ctx.world, (balance));
    set!(ctx.world, ERC721Owner { token, token_id, address: recipient });
}

fn destroy_token(ctx: Context, owner: ContractAddress, token_id: felt252) {
    let token = get_world_config(ctx.world).set;
    let mut balance = get!(ctx.world, (token, owner), ERC721Balance);
    balance.amount -= 1;
    set!(ctx.world, (balance));
    set!(ctx.world, ERC721Owner { token, token_id, address: Zeroable::zero() });
}

fn check_briqs_and_attributes_are_zero(ctx: Context, token_id: felt252) {
    // Check that we gave back all briqs (the user might attempt to lie).
    let balance = get!(ctx.world, (CUM_BALANCE_TOKEN(), CB_BRIQ, token_id), ERC1155Balance).amount;
    assert(balance == 0, 'Set still has briqs');

    // Check that we no longer have any attributes active.
    let balance = get!(ctx.world, (CUM_BALANCE_TOKEN(), CB_ATTRIBUTES, token_id), ERC1155Balance)
        .amount;
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
    use briq_protocol::world_config::{SYSTEM_CONFIG_ID, WorldConfig};

    use briq_protocol::types::{FTSpec, PackedShapeItem};

    use briq_protocol::attributes::attributes::assign_attributes;

    use debug::PrintTrait;
    use super::AssemblySystemData;

    fn execute(ctx: Context, data: AssemblySystemData) {
        let AssemblySystemData{caller, owner, token_id_hint, fts, shape, attributes } = data;

        assert(ctx.origin == caller, 'Only Caller');

        assert(shape.len() != 0, 'Cannot mint empty set');

        let token_id = super::hash_token_id(owner, token_id_hint, shape.len());
        super::create_token(ctx, owner, token_id);
        super::transfer_briqs(ctx.world, owner, token_id.try_into().unwrap(), fts.clone());

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
    token_id: felt252,
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
    use dojo_erc::erc721::components::{ERC721Owner, ERC721TokenApproval};
    use dojo_erc::erc1155::components::OperatorApproval;
    use briq_protocol::world_config::{SYSTEM_CONFIG_ID, WorldConfig, get_world_config};

    use briq_protocol::types::{FTSpec, PackedShapeItem};

    use briq_protocol::attributes::attributes::remove_attributes;

    use super::DisassemblySystemData;

    fn execute(ctx: Context, data: DisassemblySystemData) {
        let DisassemblySystemData{caller, owner, token_id, fts, attributes } = data;

        assert(ctx.origin == caller, 'Only Caller');

        let token = get_world_config(ctx.world).set;

        let token_owner = get!(ctx.world, (token, token_id), ERC721Owner);
        assert(token_owner.address.is_non_zero(), 'ERC721: invalid token_id');
        assert(token_owner.address == owner, 'SetNft: invalid owner');

        let token_approval = get!(ctx.world, (token, token_id), ERC721TokenApproval);
        let is_approved = get!(ctx.world, (token, token_owner.address, caller), OperatorApproval);

        assert(
            token_owner.address == caller
                || is_approved.approved
                || token_approval.address == caller,
            'ERC721: unauthorized caller'
        );

        remove_attributes(ctx, owner, token_id, attributes.clone(),);

        super::transfer_briqs(ctx.world, token_id.try_into().unwrap(), owner, fts.clone());

        super::check_briqs_and_attributes_are_zero(ctx, token_id);

        super::destroy_token(ctx, owner, token_id);
    }
}
