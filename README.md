# Briq Protocol

This repository contains the Cairo code for briq StarkNet contracts.

## Core contracts:

 - briq contract: ERC1155-like. Handles briq tokens. briqs have a material, and fungible & NFT briqs may have the same material. The interface is material-based instead of token-id based.
 - set contract: ERC721-like. Handles sets. Essentially a regular ERC721, but handles assembly/disassembly. When assembling, it becomes the owner of the underlying briq tokens, and vice-versa.

## Setup
#### Install python environment (via venv)
```sh
python3 -m venv venv
source venv/bin/activate
pip3 install -r requirements.txt
pip3 install -e . # For the generators utilities.
```

## Tests

```sh
pytest

# Gas-efficiency tests for the assembly with shape.
pytest -s -k box_factory_perf_test
```

## Deployment

```sh
nile run scripts/deploy.sh
```
Or
```sh
nile deploy briq_impl --alias briq_impl --network goerli
```
