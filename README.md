# Briq Protocol

This repository contains the Cairo code for briq StarkNet contracts.

## High-level overview of contracts:

 - briq contract: ERC1155-like. Handles briq tokens. briqs have a material, and fungible & NFT briqs may have the same material. The interface is material-based instead of token-id based in an ERC1155.
 - set NFT contract: ERC721-like. Handles sets. Essentially a regular ERC721, but handles assembly/disassembly. When assembling, it becomes the owner of the underlying briq tokens, and vice-versa.
 - box NFT contract: ERC1155 for Genesis boxes. Can be unboxed, granting some briqs and a booklet.
 - booklet NFT contract: ERC1155 for booklets. Acts as an attribute, refers to shapes.
 - Shape contracts: define 3D shapes for set NFTs.
 - Attribute registry: handles additional on-chain metadata for sets
 - Auction contract: for the Genesis Sale, sells boxes.

See [docs/](docs/) for more information.

## Setup
#### Install python environment (via venv)
```sh
python3 -m venv venv
source venv/bin/activate
pip3 install -r requirements.txt
pip3 install -e . # For the generators utilities.
```

Compile the target contracts:
```sh
scripts/compile.sh
```
## Tests

```sh
pytest

# Gas-efficiency tests for the assembly with shape.
pytest -s -k attributes_registry_factory_perf_test
```

## Deployment

```sh
ADMIN=0xcafe nile run scripts/deploy.py
```
Or
```sh
nile deploy briq --alias briq --network goerli
```
