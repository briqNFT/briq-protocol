%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin, SignatureBuiltin, BitwiseBuiltin

from contracts.upgrades.upgradable_mixin import (
    getAdmin_,
    getImplementation_,
    upgradeImplementation_,
    setRootAdmin_,
)

from contracts.booklet_erc1155.minting import (
    mint_
)
from contracts.booklet_erc1155.token_uri import (
    get_shape_contract_,
    get_shape_,
)

from contracts.booklet_erc1155.set_factory import (
    wrap_,
    unwrap_,
)

from contracts.ecosystem.to_set import (
    getSetAddress_,
    setSetAddress_,
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
