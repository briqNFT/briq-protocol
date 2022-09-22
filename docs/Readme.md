# briq protocol

## High-level overwiew

The briq protocol is a token-backed, customisable NFT system.

It has three core components:
- `briqs`, or `briq tokens`, are the fundamental unit. They are either fungible or non-fungible tokens. They have one on-chain characteristic: their _material_ (an arbitrary identifier).
- `sets` are the NFTs of the briq ecosystem. They are made of `briqs`, and can be minted, transferred, burned at-will by their owner. Sets are defined by a 3D matrix of briqs, and contain data such as briq position, briq colors, etc. The full shape is not stored on-chain, but a hash is.
- the `Attribute Registry` is a contract handling additional metadata for sets, such as 'This set is an official Genesis Collection set'.

Additional components include:
- `Booklets`, which are an 1155 NFT that can be 'wrapped' inside a `set` to mark it an official Genesis Collection set. This process is handled by the attributes registry and is transparent on the frontend.
- The `box` contract, which are 1155 NFTs sold by briq for the Genesis sale. Boxes are regular NFTs that can be unboxed, i.e. burned in exchanged for a booklet NFT and briq tokens.
- The `Auction` contract handles the Genesis auction sale.
- `Shape` contracts deal with 3D shapes and are used by booklets to verify that the user is constructing the correct shapes.

### Detailed contracts

Contracts are upgradable for the foreseeable future. See [`contracts/upgrades/proxy.cairo`](../contracts/upgrades/proxy.cairo) for the core proxy contract.

 - [briq contract](briq/): somewhat ERC1155-like. Handles `briq tokens`. `briqs` have a material. The interface is material-based instead of token_id based as that is a more natural usage.
 - [set contract](set/): ERC721-like. Handles `sets`. Essentially a regular ERC721, but handles assembly/disassembly. When assembling, it becomes the owner of the underlying briq tokens, and vice-versa. This vastly reduces the gas costs when transferring sets.
