%lang starknet
from starkware.cairo.common.cairo_builtins import HashBuiltin, SignatureBuiltin

from contracts.upgrades.upgradable_mixin import (
    getAdmin_,
    getImplementation_,
    upgradeImplementation_,
    setRootAdmin_,
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
    tokenURI,
)

from contracts.library_erc1155.IERC1155 import (
    approve_,
    setApprovalForAll_,
    getApproved_,
    isApprovedForAll_,
    balanceOf_,
    balanceOfBatch_,
    uri_,
    safeTransferFrom_,
)


from contracts.ecosystem.to_briq import (
    getBriqAddress_,
    setBriqAddress_,
)

from contracts.ecosystem.to_booklet import (
    getBookletAddress_,
    setBookletAddress_,
)
