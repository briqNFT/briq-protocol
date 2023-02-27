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

## Current mainnet addresses:

```
briq token (ERC1155): 0x00247444a11a98ee7896f9dec18020808249e8aad21662f2fa00402933dce402
Set NFTs (ERC721): 0x01435498bf393da86b4733b9264a86b58a42b31f8d8b8ba309593e5c17847672
Boxes (ERC1155): 0x01e1f972637ad02e0eed03b69304344c4253804e528e1a5dd5c26bb2f23a8139
Booklets (ERC1155): 0x05faa82e2aec811d3a3b14c1f32e9bbb6c9b4fd0cd6b29a823c98c7360019aa4
Attributes Registry: 0x008d4f5b0830bd49a88730133a538ccaca3048ccf2b557114b1076feeff13c11

Auction: 0x01712e3e3f133b26d65a3c5aaae78e7405dfca0a3cfe725dd57c4941d9474620 (used for Genesis Boxes sale)
Shape attribute: 0x04848d0dd8a296352ba4fe100fed9d6f44cbd0a8d360b7d551d986732a14791a (used to hash booklet shapes)
Onchain Auction: 0x00b9bb7650a88f7e375ae8d31d48b4d4f13c6c34344839837d7dae7ffcdd3df0 (used for Ducks)
```
