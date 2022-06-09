#!/bin/sh

nile compile \
    contracts/set_interface.cairo \
    contracts/briq_interface.cairo \
    contracts/booklet.cairo \
    contracts/upgrades/proxy.cairo
