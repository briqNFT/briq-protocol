%lang starknet

from starkware.cairo.common.uint256 import Uint256

###############
###############
# This interface is compatible with OZ's ERC721 api.


## Metadata
func name() -> (name: felt):
end

func symbol() -> (symbol: felt):
end

# Technically not OZ's implementation.
func tokenURI(token_id: Uint256) -> (token_uri_len: felt, token_uri: felt*):
end

func balanceOf(owner: felt) -> (balance: Uint256):
end

func ownerOf(token_id: Uint256) -> (owner: felt):
end

func safeTransferFrom(
        _from: felt, 
        to: felt, 
        token_id: Uint256, 
        data_len: felt,
        data: felt*
    ):
end

func transferFrom(_from: felt, to: felt, token_id: Uint256):
end

func approve(approved: felt, token_id: Uint256):
end

func setApprovalForAll(operator: felt, approved: felt):
end

func getApproved(token_id: Uint256) -> (approved: felt):
end

func isApprovedForAll(owner: felt, operator: felt) -> (is_approved: felt):
end

## Subset of enumerability

func tokenOfOwnerByIndex(owner: felt, index: Uint256) -> (tokenId: Uint256):
end
