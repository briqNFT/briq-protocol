mod components;
mod systems;
mod constants;

#[starknet::contract]
mod BriqFactory {
    use starknet::{get_caller_address, ClassHash};
    use dojo::world::{IWorldDispatcher, IWorldDispatcherTrait};
    use briq_protocol::world_config::AdminTrait;

    use briq_protocol::upgradeable::{IUpgradeable, UpgradeableTrait};
    #[derive(Clone, Drop, Serde, PartialEq, starknet::Event)]
    struct Upgraded {
        class_hash: ClassHash,
    }

    #[event]
    #[derive(Drop, PartialEq, starknet::Event)]
    enum Event {
        Upgraded: Upgraded
    }

    #[storage]
    struct Storage {
        world: IWorldDispatcher,
    }

    #[external(v0)]
    impl Upgradable of IUpgradeable<ContractState> {
        fn upgrade(ref self: ContractState, new_class_hash: ClassHash) {
            self.world.read().only_admins(@get_caller_address());
            UpgradeableTrait::upgrade(new_class_hash);
            self.emit(Upgraded { class_hash: new_class_hash });
        }
    }

    #[constructor]
    fn constructor(
        ref self: ContractState, world: IWorldDispatcher
    ) {
        self.world.write(world);
    }

    use dojo_erc::erc_common::utils::{system_calldata};
    use briq_protocol::briq_factory::systems::BriqFactoryBuyParams;
    use briq_protocol::briq_factory::components::{BriqFactoryTrait};
    #[external(v0)]
    fn buy(
        self: @ContractState,
        material: u64,
        amount: u32
    ) {
        self
            .world
            .read()
            .execute(
                'BriqFactoryMint',
                system_calldata(
                    BriqFactoryBuyParams {
                        caller: get_caller_address(),
                        material,
                        amount
                    }
                )
            );
    }

    #[view]
    fn get_current_t(self: @ContractState) -> felt252 {
        let briq_factory = BriqFactoryTrait::get_briq_factory(self.world.read());
        briq_factory.get_current_t()
    }

    #[view]
    fn get_surge_t(self: @ContractState) -> felt252 {
        let briq_factory = BriqFactoryTrait::get_briq_factory(self.world.read());
        briq_factory.get_surge_t()
    }
}