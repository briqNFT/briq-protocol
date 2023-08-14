#[system]
mod set_nft_mint {
    use starknet::ContractAddress;
    use traits::Into;
    use zeroable::Zeroable;

    use dojo::world::Context;
    use dojo_erc::erc721::components::{Balance, Owner};

    fn execute(
        ctx: Context, token: ContractAddress, token_id: felt252, recipient: ContractAddress
    ) {
        assert(token == ctx.origin, 'ERC721: not authorized');
        assert(recipient.is_non_zero(), 'ERC721: mint to 0');

        let token_owner = get!(ctx.world, (token, token_id), Owner);
        assert(token_owner.address.is_zero(), 'ERC721: already minted');

        // increase token supply
        let mut balance = get!(ctx.world, (token, recipient), Balance);
        balance.amount += 1;
        set!(ctx.world, (balance));
        set!(ctx.world, Owner { token, token_id, address: recipient });
    }
}

#[system]
mod set_nft_burn {
    use starknet::ContractAddress;
    use traits::Into;
    use zeroable::Zeroable;

    use dojo::world::Context;
    use dojo_erc::erc721::components::{Balance, Owner, OperatorApproval, TokenApproval};

    fn execute(ctx: Context, token: ContractAddress, caller: ContractAddress, token_id: felt252) {
        assert(token == ctx.origin, 'ERC721: not authorized');

        let token_owner = get!(ctx.world, (token, token_id), Owner);
        assert(token_owner.address.is_non_zero(), 'ERC721: invalid token_id');

        let token_approval = get!(ctx.world, (token, token_id), TokenApproval);
        let is_approved = get!(ctx.world, (token, token_owner.address, caller), OperatorApproval);
       
        assert(
            token_owner.address == caller
                || is_approved.approved
                || token_approval.address == caller,
            'ERC721: unauthorized caller'
        );

        let mut balance = get!(ctx.world, (token, token_owner.address), Balance);
        balance.amount -= 1;
        set!(ctx.world, (balance));
        set!(ctx.world, Owner { token, token_id, address: Zeroable::zero() });
    }
}
