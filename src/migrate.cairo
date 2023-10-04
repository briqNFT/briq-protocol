use starknet::ContractAddress;

use dojo_erc::token::erc1155::interface::{IERC1155Dispatcher, IERC1155DispatcherTrait};

#[starknet::contract]
mod validate_asset_migration {
    use starknet::ContractAddress;
    use starknet::get_caller_address;

    use debug::PrintTrait;

    use dojo::world::{IWorldDispatcher, IWorldDispatcherTrait};

    use briq_protocol::world_config::{AdminTrait};

    fn check_boxes(world: IWorldDispatcher, mut ids: Array<felt252>, mut owners: Array<ContractAddress>) {
        world.only_admins();

        loop {
            if ids.len() == 0 {
                break;
            }
            // TODO: check that the owner is the same
        };
    }
}
