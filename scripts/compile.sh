#!/bin/zsh

nile compile --directory contracts/vendor/ \
    contracts/set_nft.cairo \
    contracts/briq.cairo \
    contracts/box_nft.cairo \
    contracts/booklet_nft.cairo \
    contracts/attributes_registry.cairo \
    contracts/auction.cairo \
    contracts/shape_attribute.cairo \
    contracts/shape/shape_store.cairo \
    contracts/upgrades/proxy.cairo
