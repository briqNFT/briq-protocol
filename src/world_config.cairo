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
    super_admin: ContractAddress,
    treasury: ContractAddress,
    briq: ContractAddress,
    set: ContractAddress,
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
        @get!(self, (SYSTEM_CONFIG_ID), WorldConfig).super_admin == addr
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

    use dojo::world::Context;
    use super::WorldConfig;
    use super::SYSTEM_CONFIG_ID;

    fn execute(
        ctx: Context,
        super_admin: ContractAddress,
        treasury: ContractAddress,
        briq: ContractAddress,
        set: ContractAddress,
        booklet: ContractAddress,
        box: ContractAddress
    ) {
        set!(
            ctx.world,
            (WorldConfig {
                config_id: SYSTEM_CONFIG_ID, super_admin, treasury, briq, set, booklet, box,
            })
        );
        return ();
    }
}
