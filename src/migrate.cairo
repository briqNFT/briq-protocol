use serde::Serde;
use starknet::ContractAddress;
#[derive(Drop, Serde)]
struct MigrateAssetsParams {
    migrator: ContractAddress,
    current_briqs: u128,
    briqs_to_migrate: u128,
    set_to_migrate: felt252, // 0 is none

    backend_signature_r: felt252,
    backend_signature_s: felt252,
}

#[system]
mod migrate_assets {
    use dojo::world::Context;
    use super::MigrateAssetsParams;

    use core::pedersen::pedersen;
    use core::ecdsa::check_ecdsa_signature;
    use traits::Into;
    use starknet::ContractAddress;
    
    use debug::PrintTrait;

    const public_key: felt252 = 0x20c29f1c98f3320d56f01c13372c923123c35828bce54f2153aa1cfe61c44f2;

    use dojo_erc::erc721::components::{ERC721OwnerTrait, ERC721BalanceTrait, ERC721TokenApprovalTrait};
    use briq_protocol::set_nft::systems_erc721::ALL_BRIQ_SETS;

    fn execute(ctx: Context, data: MigrateAssetsParams) {
        let MigrateAssetsParams {
            migrator,
            current_briqs,
            briqs_to_migrate,
            set_to_migrate,
            backend_signature_r,
            backend_signature_s,
        } = data;


        let mut hash = pedersen(0, migrator.into());
        hash = pedersen(hash, current_briqs.into());
        hash = pedersen(hash, briqs_to_migrate.into());
        hash = pedersen(hash, set_to_migrate);
        hash = pedersen(hash, 4);
        assert(check_ecdsa_signature(hash, public_key, backend_signature_r, backend_signature_s), 'Bad signature');

        if set_to_migrate == 0 {
            // TODO: burn old token
            //ERC721OwnerTrait::unchecked_set_owner(ctx.world, ALL_BRIQ_SETS(), token_id, to);
            //ERC721BalanceTrait::unchecked_transfer_token(ctx.world, token, from, to, 1);
            //ERC721TokenApprovalTrait::unchecked_approve(ctx.world, token, token_id, Zeroable::zero());
        } else {
            // TODO: burn old briqs
        }
    }
}
