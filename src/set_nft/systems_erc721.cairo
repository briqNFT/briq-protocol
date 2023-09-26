use array::{ArrayTrait, SpanTrait};
use option::OptionTrait;
use serde::Serde;
use clone::Clone;
use traits::{Into, TryInto};
use starknet::{ContractAddress, get_contract_address};
use dojo::world::{IWorldDispatcher, IWorldDispatcherTrait};
use dojo_erc::erc721::erc721::ERC721;

use dojo_erc::erc721::erc721::ERC721::{
    IERC721EventsDispatcher, IERC721EventsDispatcherTrait, Approval, Transfer, ApprovalForAll, Event
};

use ERC721TransferFrom::ERC721TransferFromParams;

use briq_protocol::utils::IntoContractAddressU256;

// since sets token_id is an hash (into a ContractAddress) there is low collision probability
// ERC721OwnerTrait overrides token (ercXXX contract address) with ALL_BRIQ_SETS
// it allows to store ownership for all sets (generic_sets, ducks_set, ...) under one contract_address (ALL_BRIQ_SETS)
fn ALL_BRIQ_SETS() -> ContractAddress {
    'all_briq_sets'.try_into().unwrap()
}

fn emit_transfer(
    world: IWorldDispatcher,
    token: ContractAddress,
    from: ContractAddress,
    to: ContractAddress,
    token_id: felt252,
) {
    IERC721EventsDispatcher { contract_address: token }.on_transfer(Transfer { from, to, token_id: token_id.into() });
    emit!(world, Transfer { from, to, token_id: ALL_BRIQ_SETS().into() });
}

#[system]
mod ERC721TransferFrom {
    use starknet::ContractAddress;
    use starknet::get_caller_address;
    use traits::Into;
    use zeroable::Zeroable;
    use array::SpanTrait;

    use dojo_erc::erc721::components::{
        OperatorApprovalTrait, ERC721BalanceTrait, ERC721TokenApprovalTrait, ERC721OwnerTrait,
    };
    use super::ALL_BRIQ_SETS;


    #[derive(Drop, Serde)]
    struct ERC721TransferFromParams {
        caller: ContractAddress,
        token: ContractAddress,
        from: ContractAddress,
        to: ContractAddress,
        token_id: felt252
    }

    fn execute(world: IWorldDispatcher, params: ERC721TransferFromParams) {
        let ERC721TransferFromParams{caller, token, from, to, token_id } = params;

        assert(token == get_caller_address(), 'ERC721: not authorized');
        assert(!to.is_zero(), 'ERC721: invalid receiver');

        let owner = ERC721OwnerTrait::owner_of(world, ALL_BRIQ_SETS(), token_id);
        assert(owner.is_non_zero(), 'ERC721: invalid token_id');

        let is_approved_for_all = OperatorApprovalTrait::is_approved_for_all(
            world, token, owner, caller
        );
        let approved = ERC721TokenApprovalTrait::get_approved(world, token, token_id);

        assert(
            owner == caller || is_approved_for_all || approved == caller,
            'ERC721: unauthorized caller'
        );

        ERC721OwnerTrait::unchecked_set_owner(world, ALL_BRIQ_SETS(), token_id, to);
        ERC721BalanceTrait::unchecked_transfer_token(world, token, from, to, 1);
        ERC721TokenApprovalTrait::unchecked_approve(world, token, token_id, Zeroable::zero());

        // emit events
        super::emit_transfer(world, token, from, to, token_id);
    }
}
