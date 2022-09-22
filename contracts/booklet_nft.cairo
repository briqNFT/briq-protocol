%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin, SignatureBuiltin, BitwiseBuiltin

from contracts.upgrades.upgradable_mixin import (
    getAdmin_,
    getImplementation_,
    upgradeImplementation_,
    setRootAdmin_,
)

from contracts.ecosystem.to_attributes_registry import (
    getAttributesRegistryAddress_,
    setAttributesRegistryAddress_,
)

from contracts.ecosystem.to_box import (
    getBoxAddress_,
    setBoxAddress_,
)

from contracts.library_erc1155.IERC1155 import (
    approve_,
    setApprovalForAll_,
    getApproved_,
    isApprovedForAll_,
    balanceOf_,
    balanceOfBatch_,
    safeTransferFrom_,
    // no URI (yet)
)

from contracts.booklet_nft.minting import (
    mint_
)
from contracts.booklet_nft.token_uri import (
    get_shape_contract_,
    get_shape_,
)

from contracts.booklet_nft.attribute import (
    assign_attribute,
    remove_attribute,
)