use starknet::ContractAddress;

#[derive(Drop, Serde)]
struct ERC1155MintBurnParams {
    operator: ContractAddress,
    token: ContractAddress,
    from: ContractAddress,
    to: ContractAddress,
    ids: Array<felt252>,
    amounts: Array<u128>,
}

#[system]
mod ERC1155MintBurn {
    use traits::{Into, TryInto};
    use option::OptionTrait;
    use array::ArrayTrait;
    use zeroable::Zeroable;
    use starknet::ContractAddress;
    use starknet::get_caller_address;

    use briq_protocol::world_config::AdminTrait;
    use super::ERC1155MintBurnParams;

    fn execute(world: IWorldDispatcher, params: ERC1155MintBurnParams) {
        world.only_admins(@get_caller_address());

        let ERC1155MintBurnParams{operator, token, from, to, ids, amounts } = params;
        dojo_erc::erc1155::systems::unchecked_update(world, operator, token, from, to, ids, amounts, array![]);
    }
}

#[system]
mod BriqTokenERC1155MintBurn {
    use traits::{Into, TryInto};
    use option::OptionTrait;
    use array::ArrayTrait;
    use zeroable::Zeroable;
    use starknet::ContractAddress;
    use starknet::get_caller_address;

    use briq_protocol::world_config::AdminTrait;
    use super::ERC1155MintBurnParams;

    fn execute(world: IWorldDispatcher, params: ERC1155MintBurnParams) {
        world.only_admins(@get_caller_address());

        let ERC1155MintBurnParams{operator, token, from, to, ids, amounts } = params;
        briq_protocol::erc1155::briq_transfer::update_nocheck(world, operator, token, from, to, ids, amounts, array![]);
    }
}