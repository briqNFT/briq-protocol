#!/bin/sh
starknet-compile contracts/briq_backend.cairo --output artifacts/briq_backend.json --abi artifacts/briq_backend_abi.json
starknet-compile contracts/set_backend.cairo --output artifacts/set_backend.json --abi artifacts/set_backend_abi.json
