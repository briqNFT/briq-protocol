#!/bin/sh

nile compile --directory contracts/vendor/ \
    contracts/set.cairo \
    contracts/briq.cairo \
    contracts/booklet.cairo \
    contracts/box.cairo \
    contracts/auction.cairo \
    contracts/upgrades/proxy.cairo
