mod cumulative_balance;
mod felt_math;
mod types;
mod upgradeable;
mod world_config;

mod briq_factory;

mod erc {
    mod get_world;
    mod mint_burn;
    mod erc721 {
        mod components;
        mod internal_trait;
    }
    mod erc1155 {
        mod components;
        mod internal_trait;
    }
}

mod attributes {
    mod attributes;
    mod attribute_group;
    mod group_systems {
        mod briq_counter;
    }
}

mod booklet {
    mod attribute;
}

mod box_nft {
    mod unboxing;
}

mod set_nft {
    mod assembly;
}

mod tokens {
    mod box_nft;
    mod booklet_ducks;
    mod booklet_starknet_planet;
    mod briqs;
    mod set_nft;
    mod set_nft_1155;
}

//mod migrate;

//#[cfg(test)]
//mod tests;
