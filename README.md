# Briq Protocol

This repository contains the Cairo code for briq StarkNet contracts.

## High-level overview of contracts:

 - briq contract: ERC1155-like. Handles briq tokens. briqs have a material, and fungible & NFT briqs may have the same material. The interface is material-based instead of token-id based in an ERC1155.
 - set NFT contract: ERC721-like. Handles sets. Essentially a regular ERC721, but handles assembly/disassembly. When assembling, it becomes the owner of the underlying briq tokens, and vice-versa.
 - box NFT contract: ERC1155 for Genesis boxes. Can be unboxed, granting some briqs and a booklet.
 - booklet NFT contract: ERC1155 for booklets. Acts as an attribute, refers to shapes.
 - Attribute registry: handles additional on-chain metadata for sets
 - Auction contract: for the Genesis Sale, sells boxes.
 - Shape contracts: define 3D shapes for set NFTs.

See [docs/](docs/) for more information.

### Repo structure

Contracts that actually get compiled are under `contracts/` directly. They have their own subfolder for their specific logic.
`contracts/library_erc721` is the generic 721 implementation I use, which is felt-based.
`contracts/library_erc1155` is the generic 1155 implementation I use, which is felt-based.
`contracts/mocks` is used for testing convenience.

`generators` contains some Python utility to generate shape data & auction data (and some older dead code).
`tests` contain the tests.

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

Note that at the moment proxy_test.py is failing (expectedly, the tests are outdated).
```sh
pytest
```

## Deployment

Deployment is done manually but 95% there to being automatic.
Just configure a wallet using `scripts/setup_testnet_env.sh` (adapt as needed), then run `scripts/setup_contracts.sh`.
You may need to wait for pending blocks occasionally, and beware of 429 too many requests in testnet.
