use core::option::OptionTrait;
use core::traits::TryInto;
use core::traits::Into;
use starknet::ContractAddress;
use debug::PrintTrait;

use dojo::world::{IWorldDispatcher, IWorldDispatcherTrait};

const SYSTEM_CONFIG_ID: u32 = 1;

#[derive(Model, Copy, Drop, Serde)]
struct WorldConfig {
    #[key]
    config_id: u32,
    treasury: ContractAddress,
    
    briq: ContractAddress,
    generic_sets: ContractAddress,
    factory: ContractAddress,
}

#[derive(Model, Copy, Drop, Serde)]
struct SetContracts {
    #[key]
    contract: ContractAddress,
    is_active: bool
}

#[derive(Model, Copy, Drop, Serde)]
struct BoxContracts {
    #[key]
    contract: ContractAddress,
    is_active: bool
}

fn get_world_config(world: IWorldDispatcher) -> WorldConfig {
    get!(world, (SYSTEM_CONFIG_ID), WorldConfig)
}


trait AdminTrait {
    fn is_admin(self: IWorldDispatcher, addr: @ContractAddress) -> bool;
    fn only_admins(self: IWorldDispatcher, caller: @ContractAddress);

    fn is_set_contract(self: IWorldDispatcher, caller: ContractAddress) -> bool;
    fn is_box_contract(self: IWorldDispatcher, caller: ContractAddress) -> bool;
}


impl AdminTraitImpl of AdminTrait {
    fn is_admin(self: IWorldDispatcher, addr: @ContractAddress) -> bool {
        if self.is_owner(*addr, 0) {
            return true;
        }
        // Wraitii admin wallet
        if addr == @starknet::contract_address_const::<0x03eF5B02BCC5D30F3f0d35D55f365E6388fE9501ECA216cb1596940Bf41083E2>() {
            return true;
        }
        // Sylve admin wallet
        if addr == @starknet::contract_address_const::<0x044Fb5366f2a8f9f8F24c4511fE86c15F39C220dcfecC730C6Ea51A335BC99CB>() {
            return true;
        }
        false
    }

    fn only_admins(self: IWorldDispatcher, caller: @ContractAddress) {
        assert(self.is_admin(caller), 'Not authorized');
    }

    fn is_set_contract(self: IWorldDispatcher, caller: ContractAddress) -> bool {
        get!(self, (caller), SetContracts).is_active
    }
    fn is_box_contract(self: IWorldDispatcher, caller: ContractAddress) -> bool {
        get!(self, (caller), BoxContracts).is_active
    }
}

#[starknet::interface]
trait ISetupWorld<ContractState> {
    fn execute(
        ref self: ContractState,
        world: IWorldDispatcher,
        treasury: ContractAddress,
        briq: ContractAddress,
        generic_sets: ContractAddress,
        factory: ContractAddress,
    );
    fn register_set_contract(
        ref self: ContractState,
        world: IWorldDispatcher,
        set_contract: ContractAddress,
        active: bool,
    );
    fn register_box_contract(
        ref self: ContractState,
        world: IWorldDispatcher,
        box_contract: ContractAddress,
        active: bool,
    );
}

#[starknet::contract]
mod setup_world {
    use starknet::ContractAddress;
    use starknet::get_caller_address;
    use array::ArrayTrait;
    use traits::Into;
    use dojo::world::{IWorldDispatcher, IWorldDispatcherTrait};
    use super::{WorldConfig, AdminTrait, SetContracts, BoxContracts};
    use super::SYSTEM_CONFIG_ID;

    #[storage]
    struct Storage {
        world_dispatcher: IWorldDispatcher,
    }

    // TODO: components.
    use starknet::SyscallResultTrait;
    #[external(v0)]
    fn upgrade(ref self: ContractState, new_class_hash: starknet::ClassHash) {
        self.world_dispatcher.read().only_admins(@get_caller_address());
        assert(new_class_hash.is_non_zero(), 'class_hash cannot be zero');
        starknet::replace_class_syscall(new_class_hash).unwrap_syscall();
    }

    #[external(v0)]
    fn execute(
        ref self: ContractState,
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

    #[external(v0)]
    fn register_set_contract(
        ref self: ContractState,
        world: IWorldDispatcher,
        set_contract: ContractAddress,
        active: bool,
    ) {
        world.only_admins(@get_caller_address());
        set!(
            world,
            SetContracts {
                contract: set_contract,
                is_active: active,
            }
        );
    }

    #[external(v0)]
    fn register_box_contract(
        ref self: ContractState,
        world: IWorldDispatcher,
        box_contract: ContractAddress,
        active: bool,
    ) {
        world.only_admins(@get_caller_address());
        set!(
            world,
            BoxContracts {
                contract: box_contract,
                is_active: active,
            }
        );
    }
}
