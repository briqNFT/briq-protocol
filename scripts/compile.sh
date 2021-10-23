#!/bin/sh
starknet-compile contracts/briq.cairo --output briq.json --abi briq_abi.json
starknet-compile contracts/set.cairo --output set.json --abi set_abi.json
