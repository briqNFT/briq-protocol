%lang starknet
from starkware.cairo.common.cairo_builtins import HashBuiltin, SignatureBuiltin

from contracts.upgrades.upgradable_mixin import (
    getAdmin_,
    getImplementation_,
    upgradeImplementation_,
    setRootAdmin_,
)

from contracts.ecosystem.to_briq import (
    getBriqAddress_,
    setBriqAddress_,
)

from contracts.ecosystem.to_booklet import (
    getBookletAddress_,
    setBookletAddress_,
)

from contracts.box_nft.minting import (
    mint_,
)
from contracts.box_nft.unboxing import (
    unbox_,
)
from contracts.box_nft.token_uri import (
    get_box_data,
    get_box_nb,
    tokenURI_,
)

from contracts.library_erc1155.IERC1155 import (
    setApprovalForAll_,
    isApprovedForAll_,
    balanceOf_,
    balanceOfBatch_,
    safeTransferFrom_,
    supportsInterface,
)

from contracts.library_erc1155.IERC1155_OZ import (
    setApprovalForAll,
    isApprovedForAll,
    balanceOf,
    balanceOfBatch,
    safeTransferFrom,
)


from starkware.cairo.common.uint256 import Uint256
from contracts.utilities.Uint256_felt_conv import _uint_to_felt, _felt_to_uint

// URI is custom
// Not quite OZ compliant -> I return a list of felt.
@view
func uri{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    id: Uint256
) -> (uri_len: felt, uri: felt*) {
    let (tid) = _uint_to_felt(id);
    let (ul, u) = tokenURI_(token_id=tid);
    return (ul, u);
}
