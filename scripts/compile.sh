#!/bin/zsh

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

starknet-compile --no_debug_info --output artifacts/shape_store_ducks.json contracts/shape/shape_store_ducks.cairo
starknet-compile --no_debug_info --output artifacts/auction_onchain_data_goerli.json contracts/auction_onchain/data_testnet.cairo
starknet-compile --no_debug_info --output artifacts/auction_onchain_data_mainnet.json contracts/auction_onchain/data_mainnet.cairo
