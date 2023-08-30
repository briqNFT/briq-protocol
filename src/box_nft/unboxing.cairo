use traits::Into;
use traits::TryInto;
use option::OptionTrait;

use array::ArrayTrait;

use starknet::ContractAddress;

use dojo::world::IWorldDispatcher;

use briq_protocol::world_config::{get_world_config};

#[derive(Drop, Copy, Serde)]
struct BoxData {
    briq_1: felt252, // nb of briqs of material 0x1
    shape_class_hash: felt252, // Class hash of the matching shape contract
}

fn get_number_of_briqs_in_box(box_id: felt252) -> u128 {
    // TODO: use match once that's supported
    if box_id == 1 {
        return 434;
    }
    if box_id == 2 {
        return 1252;
    }
    if box_id == 3 {
        return 2636;
    }
    if box_id == 4 {
        return 431;
    }
    if box_id == 5 {
        return 1246;
    }
    if box_id == 6 {
        return 2287;
    }
    if box_id == 7 {
        return 431;
    }
    if box_id == 8 {
        return 1286;
    }
    if box_id == 9 {
        return 2392;
    }
    if box_id == 10 {
        return 60;
    } // briqmas
    assert(false, 'bad box id');
    0
}

fn get_booklet_id_for_box(box_id: felt252) -> felt252 {
    // TODO: use match once that's supported
    if box_id == 1 {
        return 0x1000000000000000000000000000000000000000000000001;
    }
    if box_id == 2 {
        return 0x2000000000000000000000000000000000000000000000001;
    }
    if box_id == 3 {
        return 0x3000000000000000000000000000000000000000000000001;
    }
    if box_id == 4 {
        return 0x4000000000000000000000000000000000000000000000001;
    }
    if box_id == 5 {
        return 0x5000000000000000000000000000000000000000000000001;
    }
    if box_id == 6 {
        return 0x6000000000000000000000000000000000000000000000001;
    }
    if box_id == 7 {
        return 0x7000000000000000000000000000000000000000000000001;
    }
    if box_id == 8 {
        return 0x8000000000000000000000000000000000000000000000001;
    }
    if box_id == 9 {
        return 0x9000000000000000000000000000000000000000000000001;
    }
    // TODO warning delta migration
    if box_id == 10 {
        return 0x1000000000000000000000000000000000000000000000002;
    } // briqmas
    assert(false, 'Invalid box id');
    0
}

fn unbox(world: IWorldDispatcher, owner: ContractAddress, box_id: felt252) {
    // Burn the box
    // TODO: use event-emitting variant
    dojo_erc::erc1155::components::ERC1155BalanceTrait::transfer_tokens(
        world,
        get_world_config(world).box,
        owner,
        Zeroable::zero(),
        array![box_id].span(),
        array![1].span(),
    );

    // Mint a booklet
    // TODO: use event-emitting variant
    dojo_erc::erc1155::components::ERC1155BalanceTrait::transfer_tokens(
        world,
        get_world_config(world).booklet,
        Zeroable::zero(),
        owner,
        array![get_booklet_id_for_box(box_id)].span(),
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
        amounts: array![get_number_of_briqs_in_box(box_id)],
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
