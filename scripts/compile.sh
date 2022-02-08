#!/bin/sh
starknet-compile contracts/briq_impl.cairo --output artifacts/briq_impl.json --abi artifacts/briq_impl_abi.json
starknet-compile contracts/set_backend.cairo --output artifacts/set_backend.json --abi artifacts/set_backend_abi.json
