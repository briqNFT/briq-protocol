#!/bin/sh
starknet-compile contracts/briq.cairo --output artifacts/briq.json --abi artifacts/briq_abi.json
starknet-compile contracts/briq_erc20_proxy.cairo --output artifacts/briq_erc20.json --abi artifacts/briq_erc20_abi.json
starknet-compile contracts/set.cairo --output artifacts/set.json --abi artifacts/set_abi.json
starknet-compile contracts/mint_proxy.cairo --output artifacts/mint_proxy.json --abi artifacts/mint_proxy_abi.json
