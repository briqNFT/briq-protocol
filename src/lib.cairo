// common
mod upgradeable;
mod utils;
mod types;
mod felt_math;
mod cumulative_balance;

mod world_config;

mod erc {
    mod get_world;
    mod erc1155 {
        mod components;
        mod internal_trait;
        mod mint_burn;
    }
}

mod booklet {
    mod attribute;
}

mod box_nft {
    mod unboxing;
}

mod tokens {
    mod box_nft;
    mod booklet_ducks;
    mod booklet_starknet_planet;
}

//mod migrate;

//mod set_nft;
//mod set_nft_1155;

//mod erc1155;
//mod briq_token;

mod attributes;

//mod briq_factory;

//#[cfg(test)]
//mod tests;
