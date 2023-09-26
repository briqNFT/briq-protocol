use core::option::OptionTrait;
use core::traits::TryInto;
use core::traits::Into;
use starknet::ContractAddress;
use debug::PrintTrait;

use dojo::world::{IWorldDispatcher, IWorldDispatcherTrait};

const SYSTEM_CONFIG_ID: u32 = 1;

#[derive(Component, Copy, Drop, Serde)]
struct WorldConfig {
    #[key]
    config_id: u32,
    treasury: ContractAddress,
    
    briq: ContractAddress,
    generic_sets: ContractAddress,
    factory: ContractAddress
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
    use starknet::get_caller_address;
    use array::ArrayTrait;
    use traits::Into;

    use super::{WorldConfig, AdminTrait};
    use super::SYSTEM_CONFIG_ID;

    fn execute(
        world: IWorldDispatcher,
        treasury: ContractAddress,
        briq: ContractAddress,
        generic_sets: ContractAddress,
        factory: ContractAddress,
    ) {
        // The first time this is called, it'll rely on the world owner.
        world.only_admins(@get_caller_address());

        set!(
            world,
            (WorldConfig {
                config_id: SYSTEM_CONFIG_ID,
                treasury,
                briq,
                generic_sets,
                factory,
            })
        );
        return ();
    }
}
