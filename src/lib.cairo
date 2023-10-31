mod cumulative_balance;
mod felt_math;
mod types;
mod upgradeable;
mod world_config;
mod supports_interface;
mod uri;

mod briq_factory;

mod erc {
    mod get_world;
    mod mint_burn;
    mod erc721 {
        mod interface;
        mod internal_trait;
        mod models;
    }
    mod erc1155 {
        mod interface;
        mod internal_trait;
        mod models;
    }
}

mod attributes {
    mod attributes;
    mod attribute_group;
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
    mod box_nft_sp;
    mod box_nft_briqmas;

    mod booklet_ducks;
    mod booklet_starknet_planet;
    mod booklet_briqmas;
    mod booklet_lil_ducks;
    mod booklet_frens_ducks;

    mod briq_token;

    mod set_nft;

    mod set_nft_ducks;
    mod set_nft_sp;
    mod set_nft_briqmas;
    mod set_nft_1155_lil_ducks;
    mod set_nft_1155_frens_ducks;
}

//mod migrate;

#[cfg(test)]
mod tests {
    mod test_utils;

    mod shapes;
    mod briq_counter;

    mod test_attributes;
    mod test_box_nft;
    mod test_briq_token;

    mod test_set_nft;
    mod test_set_nft_multiple;
    mod test_set_nft_1155;

    mod test_world_config;
    mod test_briq_factory;

    mod test_check_fts_and_shape_match;

    mod test_uri;

    // mod contract_upgrade;
    // mod test_upgradeable;

    // mod test_migrate;
}
