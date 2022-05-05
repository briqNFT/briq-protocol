%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin, SignatureBuiltin, BitwiseBuiltin

from contracts.upgrades.upgradable_mixin import (
    getAdmin_,
    getImplementation_,
    upgradeImplementation_,
    setRootAdmin_,
)

from contracts.library_erc721.approvals import ERC721_approvals
from contracts.library_erc721.balance import ERC721 as ERC721_b
from contracts.library_erc721.transferability import ERC271_transferability

from contracts.box_erc721.minting import box_minting
from contracts.box_erc721.token_uri import box_token_uri
from contracts.box_erc721.set_factory import box_set_factory
