# set contract

The set contract can be found at [`contracts/set_nft.cairo`](../../contracts/set_nft.cairo).  
Implementation is found in the [`contracts/set_nft/`](../../contracts/set_nft/) folder.

## High-level overview

The set contract is an augmented ERC 721.
Unlike most ERC 721 collections, sets can be minted, burned and modified. The process of minting/burning is called assembling/disassembling.

## Assembling/Disassembling a set

When minting a set, you pass a list of `briqs` to the assembly function. The `set` becomes the new owner of these tokens (essentially locking the tokens in the set). Inversely, when a set is disassembled/burned, the `briqs` are transferred back to the `set` owner.

Note that for gas-efficiency, the full list of briqs is expected during assembly _and_ disassembly.

## Set token ID & token URI

### Token ID

The set *token_id* is crafted very specifically. The requirements are:
- The *token_id* should not conflict with any wallet address, or the set would become owner of the wallet's briqs (and vice-versa).
- The *token_id* should be computable before the minting transaction is complete (for convenience).

To enforce these contraints, the set token_id must not be **chosable**, but nonetheless **predictable**.
The approach taken consists of on-chain hashing the wallet address & a 'hint' into the token_id. The top 192 bits are kept.
Assuming pedersen_hashing is cryptographically secure, we avoid attackers creating `sets` with the same token_id as a wallet (a fortiori a specific wallet), while remaining predictable.

### token URI

The set token URI is generally stored in its own storage_var. However, if the token URI is small enough (less than 310 bits total), we store part of it in the token ID, using the bits left free (see above, the token_id only uses 192 bits). The token ID is then frozen in place (further changes to the token URI will ignore the bit in the token ID).

Instead of storing the total length, the token URI uses the top bits of a felt (248/249/250) to store whether the token URI continues.

## API

In general, there are two versions of each view/external functions:
- One taking `felt` arguments, that end with an extra `_`.
- One taking `Uint256` arguments, that don't.

The default interface takes `Uint256` for compatibility with the OpenZeppelin contracts, which are expected to become standard on Cairo. However, since sets are Cairo-native, the set contract uses `felt` internally for efficiency.

### Balance

The usual ERC 721 functions are provided: `balanceOf`, `ownerOf`, along with `tokenOfOwnerByIndex` & `balanceDetailsOf` to get the full list.

### Transfer

Only `transferFrom` is currently implemented.
