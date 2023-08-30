use core::array::SpanTrait;
use starknet::{ContractAddress, get_contract_address};
use zeroable::Zeroable;
use array::ArrayTrait;
use option::OptionTrait;
use serde::Serde;
use clone::Clone;
use traits::{Into, TryInto};

use dojo::world::{IWorldDispatcher, IWorldDispatcherTrait};

use dojo_erc::erc1155::erc1155::ERC1155::{TransferSingle, TransferBatch};
use dojo_erc::erc1155::erc1155::ERC1155::{IERC1155EventsDispatcher, IERC1155EventsDispatcherTrait};
use dojo_erc::erc1155::components::{ERC1155BalanceTrait, OperatorApprovalTrait};
use dojo_erc::erc1155::systems::{emit_transfer_batch, emit_transfer_single};

use briq_protocol::cumulative_balance::{CUM_BALANCE_TOKEN, CB_BRIQ};


fn update_nocheck(
    world: IWorldDispatcher,
    operator: ContractAddress,
    token: ContractAddress,
    from: ContractAddress,
    to: ContractAddress,
    ids: Array<felt252>,
    amounts: Array<u128>,
    data: Array<u8>
) {
    let mut ids_span = ids.span();
    let mut amounts_span = amounts.span();
    loop {
        if to.is_zero() || ids_span.len() == 0 {
            break;
        }
        let amnt = amounts_span.pop_front().unwrap();
        let balance = ERC1155BalanceTrait::balance_of(
            world, token, to, *ids_span.pop_front().unwrap()
        );
        if amnt != @0 && balance == 0 {
            ERC1155BalanceTrait::unchecked_transfer_tokens(
                world,
                CUM_BALANCE_TOKEN(),
                Zeroable::zero(),
                to,
                array![CB_BRIQ()].span(),
                array![1].span()
            );
        };
    };

    ERC1155BalanceTrait::unchecked_transfer_tokens(world, token, from, to, ids.span(), amounts.span());

    let mut ids_span = ids.span();
    let mut amounts_span = amounts.span();
    loop {
        if from.is_zero() || ids_span.len() == 0 {
            break;
        }
        let amnt = amounts_span.pop_front().unwrap();
        let balance = ERC1155BalanceTrait::balance_of(
            world, token, from, *ids_span.pop_front().unwrap()
        );
        if amnt != @0 && balance == 0 {
            ERC1155BalanceTrait::unchecked_transfer_tokens(
                world,
                CUM_BALANCE_TOKEN(),
                from,
                Zeroable::zero(),
                array![CB_BRIQ()].span(),
                array![1].span()
            );
        };
    };

    if (ids.len() == 1) {
        let id = *ids.at(0);
        let amount = *amounts.at(0);

        emit_transfer_single(world, token, operator, from, to, id, amount);

        if (to
            .is_non_zero()) { //do_safe_transfer_acceptance_check(operator, from, to, id.into(), amount.into(), data);
        } else {
            emit_transfer_batch(world, token, operator, from, to, ids.span(), amounts.span());
            if (to.is_non_zero()) { //do_safe_batch_transfer_acceptance_check(
            //    operator, from, to, ids, amounts, data
            //);
            }
        }
    }
}

fn update(
    world: IWorldDispatcher,
    operator: ContractAddress,
    token: ContractAddress,
    from: ContractAddress,
    to: ContractAddress,
    ids: Array<felt252>,
    amounts: Array<u128>,
    data: Array<u8>
) {
    assert(ids.len() == amounts.len(), 'ERC1155: invalid length');

    assert(
        operator == from
            || OperatorApprovalTrait::is_approved_for_all(world, token, from, operator),
        'ERC1155: insufficient approval'
    );

    update_nocheck(world, operator, token, from, to, ids, amounts, data)
}

#[system]
mod BriqTokenSafeTransferFrom {
    use traits::{Into, TryInto};
    use option::OptionTrait;
    use array::ArrayTrait;
    use dojo::world::Context;
    use zeroable::Zeroable;
    use starknet::ContractAddress;

    fn execute(
        ctx: Context,
        operator: ContractAddress,
        token: ContractAddress,
        from: ContractAddress,
        to: ContractAddress,
        id: felt252,
        amount: u128,
        data: Array<u8>
    ) {
        assert(ctx.origin == operator || ctx.origin == token, 'ERC1155: not authorized');
        assert(to.is_non_zero(), 'ERC1155: to cannot be 0');

        super::update(ctx.world, operator, token, from, to, array![id], array![amount], data);
    }
}

#[system]
mod BriqTokenSafeBatchTransferFrom {
    use traits::{Into, TryInto};
    use option::OptionTrait;
    use array::ArrayTrait;
    use dojo::world::Context;
    use zeroable::Zeroable;
    use starknet::ContractAddress;

    fn execute(
        ctx: Context,
        operator: ContractAddress,
        token: ContractAddress,
        from: ContractAddress,
        to: ContractAddress,
        ids: Array<felt252>,
        amounts: Array<u128>,
        data: Array<u8>
    ) {
        assert(ctx.origin == operator || ctx.origin == token, 'ERC1155: not authorized');
        assert(to.is_non_zero(), 'ERC1155: to cannot be 0');

        super::update(ctx.world, operator, token, from, to, ids, amounts, data);
    }
}


#[system]
mod ERC1155MintBurn {
    use traits::{Into, TryInto};
    use option::OptionTrait;
    use array::ArrayTrait;
    use dojo::world::Context;
    use zeroable::Zeroable;
    use starknet::ContractAddress;

    use briq_protocol::world_config::AdminTrait;

    fn execute(
        ctx: Context,
        operator: ContractAddress,
        token: ContractAddress,
        from: ContractAddress,
        to: ContractAddress,
        ids: Array<felt252>,
        amounts: Array<u128>,
    ) {
        ctx.world.only_admins(@ctx.origin);

        super::update_nocheck(ctx.world, operator, token, from, to, ids, amounts, array![]);
    }
}
