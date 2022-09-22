#!/bin/sh

nile compile --directory contracts/vendor/ \
    contracts/set_nft.cairo \
    contracts/briq.cairo \
    contracts/attributes_registry.cairo \
    contracts/box_nft.cairo \
    contracts/booklet_nft.cairo \
    contracts/auction.cairo \
    contracts/upgrades/proxy.cairo
