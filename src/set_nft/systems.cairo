use starknet::ContractAddress;
use traits::{Into, TryInto};
use array::ArrayTrait;
use array::SpanTrait;
use option::{Option, OptionTrait};
use zeroable::Zeroable;

use core::pedersen::pedersen;
use dojo::world::{Context, IWorldDispatcher, IWorldDispatcherTrait};

use dojo_erc::erc1155::components::{OperatorApproval, ERC1155Balance, ERC1155BalanceTrait};
use dojo_erc::erc1155::interface::{IERC1155DispatcherTrait, IERC1155Dispatcher};

use dojo_erc::erc721::components::{
    ERC721Balance, ERC721BalanceTrait, ERC721Owner, ERC721OwnerTrait, ERC721TokenApproval,
    ERC721TokenApprovalTrait
};

use briq_protocol::set_nft::systems_erc721::emit_transfer;

use briq_protocol::world_config::{WorldConfig, get_world_config};
use briq_protocol::cumulative_balance::{CUM_BALANCE_TOKEN, CB_BRIQ, CB_ATTRIBUTES};
use briq_protocol::set_nft::systems_erc721::ALL_BRIQ_SETS;
use briq_protocol::attributes::attributes::remove_attributes;
use briq_protocol::attributes::attribute_group::AttributeGroupTrait;
use briq_protocol::types::{FTSpec, PackedShapeItem, AttributeItem};
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
                briq_protocol::erc1155::briq_transfer::update_nocheck(
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


// https://github.com/xJonathanLEI/starknet-rs/blob/master/starknet-accounts/src/factory/mod.rs#L36
// 2 ** 251 - 256   
// = 0x800000000000000000000000000000000000000000000000000000000000000 - 0x100
// = 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF00
const ADDR_BOUND: u256 = 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF00;
const TOKEN_ID_MASK: u256 = 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF00000000;

// To prevent people from generating collisions, we need the token_id to be random.
// However, we need it to be predictable for good UI.
// The solution adopted is to hash a hint. Our security becomes the chain hash security.
// Hash on the # of briqs to avoid people being able to 'game' off-chain latency,
// we had issues where people regenerated sets with the wrong # of briqs shown on marketplaces before a refresh.
// The set will take ownership of briqs/booklet/attributes therefore we use a ContractAddress.
// To ensure there are no collisions with 1155 sets (or for that matter official sets)
// reserve some bytes at the end.
fn get_token_id(owner: ContractAddress, token_id_hint: felt252, nb_briqs: u32, attribute_group_id: u64) -> ContractAddress {
    let hash = pedersen(0, owner.into());
    let hash = pedersen(hash, token_id_hint);
    let hash = pedersen(hash, nb_briqs.into());
    let two_power_32 = 0x100000000;
    let mut hash_256: u256 = hash.into();
    hash_256 = (hash_256 & TOKEN_ID_MASK) + attribute_group_id.into();
    let hash_252: felt252 = (hash_256 % ADDR_BOUND).try_into().unwrap();

    hash_252.try_into().unwrap()
}

fn get_1155_token_id(attrib: AttributeItem) -> ContractAddress {
    let two_power_32 = 0x100000000_u256;
    assert(attrib.attribute_group_id.into() < two_power_32, 'Attribute group too large');
    let token_256: u256 = (attrib.attribute_id.into() * two_power_32 + attrib.attribute_group_id.into());
    let token_252: felt252 = (token_256 % ADDR_BOUND).try_into().unwrap();

    token_252.try_into().unwrap()
}

fn get_target_contract_from_attributes(
    world: IWorldDispatcher, arr: @Array<AttributeItem>
) -> (ContractAddress, Option::<AttributeItem>) {
    let mut token = get_world_config(world).generic_sets;
    let mut attrib = Option::<AttributeItem>::None;
    let mut span = arr.span();
    loop {
        match span.pop_front() {
            Option::Some(attribute_item) => {
                let attribute_group = AttributeGroupTrait::get_attribute_group(
                    world, *attribute_item.attribute_group_id
                );
                if attribute_group.target_set_contract_address.is_non_zero() {
                    token = attribute_group.target_set_contract_address;
                    attrib = Option::<AttributeItem>::Some(*attribute_item);
                    break;
                }
            },
            Option::None => {
                break;
            }
        };
    };
    (token, attrib)
}

fn create_token(
    ctx: Context, token: ContractAddress, recipient: ContractAddress, token_id: felt252
) {
    assert(recipient.is_non_zero(), 'ERC721: mint to 0');

    let token_owner = ERC721OwnerTrait::owner_of(ctx.world, ALL_BRIQ_SETS(), token_id);
    assert(token_owner.is_zero(), 'ERC721: already minted');

    // increase token supply
    ERC721BalanceTrait::unchecked_increase_balance(ctx.world, token, recipient, 1);
    ERC721OwnerTrait::unchecked_set_owner(ctx.world, ALL_BRIQ_SETS(), token_id, recipient);

    emit_transfer(ctx.world, token, Zeroable::zero(), recipient, token_id.into());
}

fn destroy_token(
    ctx: Context, token: ContractAddress, owner: ContractAddress, token_id: ContractAddress
) {
    // decrease token supply
    ERC721BalanceTrait::unchecked_decrease_balance(ctx.world, token, owner, 1);
    ERC721OwnerTrait::unchecked_set_owner(
        ctx.world, ALL_BRIQ_SETS(), token_id.into(), Zeroable::zero()
    );
    emit_transfer(ctx.world, token, owner, Zeroable::zero(), token_id.into());
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
    name: Array<felt252>, // todo string
    description: Array<felt252>, // todo string
    fts: Array<FTSpec>,
    shape: Array<PackedShapeItem>,
    attributes: Array<AttributeItem>
}

#[system]
mod set_nft_assembly {
    use starknet::ContractAddress;
    use traits::Into;
    use traits::TryInto;
    use array::{ArrayTrait, SpanTrait};
    use option::OptionTrait;
    use zeroable::Zeroable;
    use clone::Clone;
    use serde::Serde;

    use dojo::world::Context;
    use briq_protocol::world_config::{WorldConfig};

    use briq_protocol::types::{FTSpec, PackedShapeItem};

    use briq_protocol::attributes::attributes::assign_attributes;
    use briq_protocol::set_nft::systems::get_target_contract_from_attributes;

    use super::AssemblySystemData;

    use debug::PrintTrait;

    fn execute(ctx: Context, data: AssemblySystemData) {
        let AssemblySystemData{caller, owner, token_id_hint, name, description, fts, shape, attributes } = data;

        let (token, attrib_option) = get_target_contract_from_attributes(ctx.world, @attributes);

        if ctx.origin != owner {
            assert(ctx.origin == token, 'Only Caller');
        }
        assert(owner == caller, 'Only Owner');
        assert(shape.len() != 0, 'Cannot mint empty set');

        let mut attribute_group_id = 0;
        if attrib_option.is_some() {
            attribute_group_id = attrib_option.unwrap().attribute_group_id;
        }

        let token_id = super::get_token_id(owner, token_id_hint, shape.len(), attribute_group_id);
        super::create_token(ctx, token, owner, token_id.into());
        super::transfer_briqs(ctx.world, owner, token_id, fts.clone());

        assign_attributes(ctx, owner, token_id, @attributes, @shape, @fts,);
    }
}


#[derive(Drop, Serde)]
struct DisassemblySystemData {
    caller: ContractAddress,
    owner: ContractAddress,
    token_id: ContractAddress,
    fts: Array<FTSpec>,
    attributes: Array<AttributeItem>
}


#[system]
mod set_nft_disassembly {
    use starknet::ContractAddress;
    use traits::{TryInto, Into};
    use array::{ArrayTrait, SpanTrait};
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
    use briq_protocol::set_nft::systems::get_target_contract_from_attributes;
    use briq_protocol::set_nft::systems_erc721::ALL_BRIQ_SETS;

    use super::DisassemblySystemData;

    fn execute(ctx: Context, data: DisassemblySystemData) {
        let DisassemblySystemData{caller, owner, token_id, fts, attributes } = data;


        let (token, _) = get_target_contract_from_attributes(ctx.world, @attributes);

        if ctx.origin != owner {
            assert(ctx.origin == token, 'Only Caller');
        }
        assert(owner == caller, 'Only Owner');

        let token_owner = ERC721OwnerTrait::owner_of(ctx.world, ALL_BRIQ_SETS(), token_id.into());

        assert(token_owner.is_non_zero(), 'ERC721: invalid token_id');
        assert(token_owner == owner, 'SetNft: invalid owner');

        remove_attributes(ctx, owner, token_id, attributes.clone(),);

        super::transfer_briqs(ctx.world, token_id, owner, fts.clone());
        super::check_briqs_and_attributes_are_zero(ctx, token_id);
        super::destroy_token(ctx, token, owner, token_id);
    }
}


#[system]
mod set_nft_1155_assembly {
    use starknet::ContractAddress;
    use traits::Into;
    use traits::TryInto;
    use array::{ArrayTrait, SpanTrait};
    use option::OptionTrait;
    use zeroable::Zeroable;
    use clone::Clone;
    use serde::Serde;

    use dojo::world::Context;
    use briq_protocol::world_config::{WorldConfig};

    use briq_protocol::types::{FTSpec, PackedShapeItem};

    use briq_protocol::attributes::attributes::assign_attributes;
    use briq_protocol::set_nft::systems::get_target_contract_from_attributes;

    use dojo_erc::erc1155::components::ERC1155BalanceTrait;
    use briq_protocol::cumulative_balance::{CUM_BALANCE_TOKEN, CB_TOTAL_SUPPLY_1155};

    use super::{get_1155_token_id, AssemblySystemData};

    use debug::PrintTrait;

    fn execute(ctx: Context, data: AssemblySystemData) {
        let AssemblySystemData{caller, owner, token_id_hint, name, description, fts, shape, attributes } = data;

        // Check that we are asking for the attribute group that matches this contract
        // (could be hardcoded instead?)
        let (token, attrib_option) = get_target_contract_from_attributes(ctx.world, @attributes);
        let attrib = attrib_option.unwrap().into();
        assert(token == ctx.origin, 'Not the correct caller');
        assert(owner == caller, 'Only Owner');
        assert(shape.len() != 0, 'Cannot mint empty set');

        // Token ID is the attribute ID for simplicity, and attribute group as bitpacking marker.
        let token_id: felt252 = get_1155_token_id(attrib).into();

        dojo_erc::erc1155::systems::unchecked_update(
            ctx.world, caller, token, Zeroable::zero(), owner, array![token_id], array![1], array![]
        );

        super::transfer_briqs(ctx.world, owner, token_id.try_into().unwrap(), fts.clone());

        // no events
        ERC1155BalanceTrait::unchecked_increase_balance(
            ctx.world, CUM_BALANCE_TOKEN(), token_id.try_into().unwrap(), CB_TOTAL_SUPPLY_1155(), 1
        );

        assign_attributes(ctx, owner, token_id.try_into().unwrap(), @attributes, @shape, @fts,);
    }
}

#[system]
mod set_nft_1155_disassembly {
    use starknet::ContractAddress;
    use traits::{TryInto, Into};
    use array::{ArrayTrait, SpanTrait};
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
    use briq_protocol::set_nft::systems::get_target_contract_from_attributes;
    use briq_protocol::set_nft::systems_erc721::ALL_BRIQ_SETS;

    use dojo_erc::erc1155::components::ERC1155BalanceTrait;
    use briq_protocol::cumulative_balance::{CUM_BALANCE_TOKEN, CB_BRIQ, CB_ATTRIBUTES, CB_TOTAL_SUPPLY_1155};

    use super::DisassemblySystemData;

    use debug::PrintTrait;

    fn execute(ctx: Context, data: DisassemblySystemData) {
        let DisassemblySystemData{caller, owner, token_id, fts, attributes } = data;

        // Check that we are asking for the attribute group that matches this contract
        // (could be hardcoded instead?)
        let (token, o_attribute_id) = get_target_contract_from_attributes(ctx.world, @attributes);
        assert(token == ctx.origin, 'Not the correct caller');
        assert(owner == caller, 'Only Owner');


        let nb_briq_tokens = ERC1155BalanceTrait::balance_of(
            ctx.world, CUM_BALANCE_TOKEN(), token_id, CB_BRIQ()
        );
        assert(fts.len().into() == nb_briq_tokens, 'not enough fts');
        let mut prev_briqs = ArrayTrait::<FTSpec>::new();
        let mut ftsp = fts.span();
        loop {
            if ftsp.len() == 0 {
                break;
            }
            let ftspec = *ftsp.pop_front().unwrap();
            prev_briqs.append(FTSpec { token_id: ftspec.token_id, qty: ERC1155BalanceTrait::balance_of(
                ctx.world, get_world_config(ctx.world).briq, token_id, ftspec.token_id
            )});
        };

        let prev_attrib = ERC1155BalanceTrait::balance_of(
            ctx.world, CUM_BALANCE_TOKEN(), token_id, CB_ATTRIBUTES()
        );

        super::transfer_briqs(ctx.world, token_id, owner, fts.clone());

        dojo_erc::erc1155::systems::unchecked_update(
            ctx.world, caller, token, owner, Zeroable::zero(), array![token_id.into()], array![1], array![]
        );

        ERC1155BalanceTrait::unchecked_decrease_balance(
            ctx.world, CUM_BALANCE_TOKEN(), token_id, CB_TOTAL_SUPPLY_1155(), 1
        );

        remove_attributes(ctx, owner, token_id, attributes.clone(),);

        let post_attrib = ERC1155BalanceTrait::balance_of(
            ctx.world, CUM_BALANCE_TOKEN(), token_id, CB_ATTRIBUTES()
        );

        let remaining_supply = ERC1155BalanceTrait::balance_of(
            ctx.world, CUM_BALANCE_TOKEN(), token_id, CB_TOTAL_SUPPLY_1155()
        );

        assert(post_attrib / (prev_attrib - post_attrib) == remaining_supply, 'Set still has attribs');

        loop {
            if prev_briqs.len() == 0 {
                break;
            }
            let pre_briq = prev_briqs.pop_front().unwrap();
            let post_briq = ERC1155BalanceTrait::balance_of(
                ctx.world, get_world_config(ctx.world).briq, token_id, pre_briq.token_id
            );
            assert(post_briq / (pre_briq.qty - post_briq) == remaining_supply, 'Set still has briqs');
        };
    }
}
