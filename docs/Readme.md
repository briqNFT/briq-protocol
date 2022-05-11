# briq protocol

## High-level overwiew

The briq protocol is a token-backed, customisable NFT system.

It has two core components:
- `briqs`, or `briq tokens`, are the fundamental unit. They are either fungible or non-fungible tokens. They have one on-chain characteristic: their _material_ (an arbitrary identifier).
- `sets` are the NFTs of the briq ecosystem. They are made of `briqs`, and can be minted, burned, and, critically, **modified** at-will by their owner. Sets are defined by complex metadata, stored in a JSON format (TODO: document).

### Core contracts

Both contracts are upgradable for the foreseeable future. See [`contracts/upgrades/proxy.cairo`](../contracts/upgrades/proxy.cairo) for the core proxy contract.

 - [briq contract](briq/): somewhat ERC1155-like. Handles `briq tokens`. `briqs` have a material. The interface is material-based instead of token_id based as that is a more natural usage.
 - [set contract](set/): ERC721-like. Handles `sets`. Essentially a regular ERC721, but handles assembly/disassembly. When assembling, it becomes the owner of the underlying briq tokens, and vice-versa. This vastly reduces the gas costs when transferring sets.
