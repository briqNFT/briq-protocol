#!/bin/zsh

compile () {
    starknet-compile --no_debug_info --cairo_path contracts/vendor/ --output artifacts/$1.json contracts/$2.cairo
    jq '.abi' --indent 4 artifacts/$1.json > artifacts/abis/$1.json
}

nile compile --directory contracts/vendor/ \
    contracts/set_nft.cairo \
    contracts/briq.cairo \
    contracts/box_nft.cairo \
    contracts/booklet_nft.cairo \
    contracts/attributes_registry.cairo \
    contracts/auction.cairo \
    contracts/auction_onchain.cairo \
    contracts/shape_attribute.cairo \
    contracts/shape/shape_store.cairo \
    contracts/upgrades/proxy.cairo


compile set_nft set_nft
compile briq briq
compile box_nft box_nft
compile booklet_nft booklet_nft
compile attributes_registry attributes_registry


compile shape_store_ducks shape/shape_store_ducks
compile shape_store_zenducks shape/shape_store_zenducks
compile auction_onchain_data_goerli auction_onchain/data_testnet
compile auction_onchain_data_mainnet auction_onchain/data_mainnet
