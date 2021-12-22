#!/bin/sh
starknet-compile contracts/briq.cairo --output briq.json --abi briq_abi.json
starknet-compile contracts/briq_erc20_proxy.cairo --output briq_erc20.json --abi briq_erc20_abi.json
starknet-compile contracts/set.cairo --output set.json --abi set_abi.json
starknet-compile contracts/mint_proxy.cairo --output mint_proxy.json --abi mint_proxy_abi.json
