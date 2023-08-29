use core::option::OptionTrait;
use core::traits::TryInto;
use core::traits::Into;
use starknet::ContractAddress;
use debug::PrintTrait;

use dojo::world::{IWorldDispatcher, IWorldDispatcherTrait};

const SYSTEM_CONFIG_ID: u32 = 1;

#[derive(Component, Copy, Drop, Serde, SerdeLen)]
struct WorldConfig {
    #[key]
    config_id: u32,
    treasury: ContractAddress,
    briq: ContractAddress,
    set: ContractAddress,
    set2: ContractAddress,
    booklet: ContractAddress,
    box: ContractAddress,
}

fn get_world_config(world: IWorldDispatcher) -> WorldConfig {
    get!(world, (SYSTEM_CONFIG_ID), WorldConfig)
}


trait AdminTrait {
    fn is_admin(self: IWorldDispatcher, addr: @ContractAddress) -> bool;
    fn only_admins(self: IWorldDispatcher, caller: @ContractAddress);
}


impl AdminTraitImpl of AdminTrait {
    fn is_admin(self: IWorldDispatcher, addr: @ContractAddress) -> bool {
        if self.is_owner(*addr, 0) {
            return true;
        }
        false
    }

    fn only_admins(self: IWorldDispatcher, caller: @ContractAddress) {
        assert(self.is_admin(caller), 'Not authorized');
    }
}

#[system]
mod SetupWorld {
    use starknet::ContractAddress;
    use array::ArrayTrait;
    use traits::Into;

    use briq_protocol::world_config::AdminTrait;

    use dojo::world::Context;
    use super::WorldConfig;
    use super::SYSTEM_CONFIG_ID;

    fn execute(
        ctx: Context,
        treasury: ContractAddress,
        briq: ContractAddress,
        set: ContractAddress,
        set2: ContractAddress,
        booklet: ContractAddress,
        box: ContractAddress
    ) {
        ctx.world.only_admins(@ctx.origin);

        set!(
            ctx.world,
            (WorldConfig { config_id: SYSTEM_CONFIG_ID, treasury, briq, set, set2, booklet, box, })
        );
        return ();
    }
}
