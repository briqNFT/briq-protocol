#!/bin/sh

nile compile --directory contracts/vendor/ \
    contracts/set_interface.cairo \
    contracts/briq_interface.cairo \
    contracts/booklet.cairo \
    contracts/box.cairo \
    contracts/auction.cairo \
    contracts/upgrades/proxy.cairo
