# briq contract

The briq contract can be found at [`contracts/briq_interface.cairo`](../../contracts/briq_interface.cairo).  
Implementation is found in the [`contracts/briq_erc1155_like/`](../../contracts/briq_erc1155_like/) folder.

## High-level overview

The briq contract should be thought of as an ERC-1155 with a slightly tweaked interface.  
`briqs` have a _material_, and that _material_ is how you'll generally talk to the contract, instead of specific token IDs. This is why `briqs` can be either fungible or non-fungible.

The ability to directly transfer briqs is currently partly implemented. You can only directly send briqs to another person, as there is no authorization handling.

The briq contract also contains functions to convert the fungibility of briqs, and to change their material, under [`contracts/briq_erc1155_like/convert_mutate.cairo`](../../contracts/briq_erc1155_like/convert_mutate.cairo). Those functions are currently unused & can only be called by admins of the contract.

## Fungible, non-fungible briq tokens & material support

To support materials efficiently, the _material_ of a `briq` is embedded inside its *token_id* (in ERC-1155 parlance).  
As a reminder, `felt` are [0-2^251[ (and change).  
The lowest 64 bits are reserved for the material. The other 187 bits are reserved for NFT unique IDS.

Material 0 does not exist. Likewise, the `briq` of *token_id* 0 does not exist.

In practice, Fungible tokens have the same *token_id* as their material. Non-fungible tokens are described by `2 ^ 64 * nft_id + material`.

## API

In general, there are two versions of each view/external functions:
- One taking `felt` arguments, that end with an extra `_`.
- One taking `Uint256` arguments, that don't.

Note that at the moment, both are `felt`-based, but that's expected to change (contrast the set contract).s

### Balance

In general, you'll query the balance of a given _material_, not a given token_id as in ERC1155.  
`balanceOfMaterial` is your regular `balanceOf`, but takes a material. `fullBalanceOf` returns the complete balance, but iterates over materials internally. Use `materialsOf` to query those directly.  
You also have `balanceOfMaterials` to query several materials.  
`ownerOf` will return the owner of a specific `briq NFT` token. Querying the owner of a fungible token returns 0.  
`balanceDetailsOfMaterial` will return the full list of NFTs for a given material. You may also use `tokenOfOwnerByIndex`.

`totalSupplyOfMaterial` returns the total number of fungible & non-fungible tokens of a given material.

### Minting

#### Fungible tokens:
`mintFT` takes a recipient, a material, and a quantity of token to mint.

#### Non-fungible tokens:
`mintOneNFT` takes a recipient, a material, and a unique identifier for the token.  
Note that if the same `briq NFT` exists (same material and token id), the minting will fail.

### Transfer

Transfer is implemented for owners, without approval & such for now.
The `set contract` is always authorized to transfer briqs, which is required for minting/burning (see [set contract](../set/) ).

### Conversion / Mutation

Those functions are intended to make NFT `briqs` into FT `briqs` and vice-versa, and to change `briq` material. They mostly exist in-case we discover a need for them in the future.
