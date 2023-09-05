use traits::{Into,TryInto};
use option::OptionTrait;
use array::{ArrayTrait,SpanTrait};
use starknet::ContractAddress;

use dojo::world::IWorldDispatcher;
use briq_protocol::world_config::{get_world_config};
use briq_protocol::attributes::attribute_group::{AttributeGroup, AttributeGroupTrait};

// starknet planets : attribute_group_id: 1
// briqmas          : attribute_group_id: 2
// ducks            : attribute_group_id: 
// lil ducks        : attribute_group_id: 


#[derive(Drop, Copy, Serde)]
struct BoxInfos {
    briq_1: u128, // nb of briqs of material 0x1
    attribute_group_id: u64,
    attribute_id: u64,
}

fn get_box_infos(box_id: felt252) -> BoxInfos {

    // starknet planets
    if box_id == 1 {
        return BoxInfos { briq_1: 434, attribute_group_id: 1, attribute_id: 1 };
    } else if box_id == 2 {
        return BoxInfos { briq_1: 1252, attribute_group_id: 1, attribute_id: 2 };
    } else if box_id == 3 {
        return BoxInfos { briq_1: 2636, attribute_group_id: 1, attribute_id: 3 };
    } else if box_id == 4 {
        return BoxInfos { briq_1: 431, attribute_group_id: 1, attribute_id: 4 };
    } else if box_id == 5 {
        return BoxInfos { briq_1: 1246, attribute_group_id: 1, attribute_id: 5 };
    } else if box_id == 6 {
        return BoxInfos { briq_1: 2287, attribute_group_id: 1, attribute_id: 6 };
    } else if box_id == 7 {
        return BoxInfos { briq_1: 431, attribute_group_id: 1, attribute_id: 7 };
    } else if box_id == 8 {
        return BoxInfos { briq_1: 1286, attribute_group_id: 1, attribute_id: 8 };
    } else if box_id == 9 {
        return BoxInfos { briq_1: 2392, attribute_group_id: 1, attribute_id: 9 };
    } else if box_id == 10 {
        // briqmas
        return BoxInfos { briq_1: 60, attribute_group_id: 2, attribute_id: 10 };
    }

    assert(false, 'invalid box id');
    BoxInfos { briq_1: 0, attribute_group_id: 0, attribute_id: 0 }
}

fn unbox(world: IWorldDispatcher, owner: ContractAddress, box_id: felt252) {

    let box_infos = get_box_infos(box_id);
    let attribute_group = AttributeGroupTrait::get_attribute_group(world, box_infos.attribute_group_id);

    // Burn the box
    // TODO: use event-emitting variant
    dojo_erc::erc1155::components::ERC1155BalanceTrait::unchecked_transfer_tokens(
        world,
        get_world_config(world).box,
        owner,
        Zeroable::zero(),
        array![box_id].span(),
        array![1].span(),
    );

    // Mint a booklet
    // TODO: use event-emitting variant
    dojo_erc::erc1155::components::ERC1155BalanceTrait::unchecked_transfer_tokens(
        world,
        attribute_group.booklet_contract_address,
        Zeroable::zero(),
        owner,
        array![box_infos.attribute_id.into()].span(),
        array![1].span(),
    );

    // TODO: register a specific shape verifier for this booklet ?
    // Or will that be handled directly by a different system maybe...

    // Mint briqs
    briq_protocol::briq_token::systems::update_nocheck(
        world,
        owner,
        get_world_config(world).briq,
        from: Zeroable::zero(),
        to: owner,
        ids: array![1],
        amounts: array![box_infos.briq_1],
        data: array![]
    );
}

// Unbox burns the box NFT, and mints briqs & attributes_registry corresponding to the token URI.
#[system]
mod box_unboxing {
    use traits::{Into, TryInto};
    use option::OptionTrait;
    use array::ArrayTrait;
    use dojo::world::Context;
    use zeroable::Zeroable;
    use starknet::ContractAddress;

    fn execute(ctx: Context, box_id: felt252,) {
        // Only the owner may unbox their box.
        super::unbox(ctx.world, ctx.origin, box_id);
    }
}
