# Just a proxy for importing from the subfiles.
# TODO: auto-generate this maybe.
%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin, SignatureBuiltin, BitwiseBuiltin

from contracts.upgrades.upgradable_mixin import (
    getAdmin_,
    getImplementation_,
    upgradeImplementation_,
    setRootAdmin_,
)

from contracts.set_erc721.link_to_ecosystem import set_ecosystem

from contracts.library_erc721.approvals import ERC721_approvals
from contracts.library_erc721.balance import ERC721 as ERC721_balance
from contracts.library_erc721.enumerability import ERC721_enumerability

from contracts.set_erc721.token_uri import (
    tokenURI_,
    tokenURIData_,
    setTokenURI_,
    is_realms_set_,
)

from contracts.library_erc721.transferability_enum import ERC721_transferability

from contracts.set_erc721.assembly import (
    assemble_,
    disassemble_,
)

from contracts.types import FTSpec

# Temporary retro-compatibility interface.

@external
func assemble{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, bitwise_ptr: BitwiseBuiltin*, range_check_ptr
    } (owner: felt, token_id_hint: felt, fts_len: felt, fts: FTSpec*, nfts_len: felt, nfts: felt*, uri_len: felt, uri: felt*):
    assemble_(owner, token_id_hint, fts_len, fts, nfts_len, nfts, uri_len, uri)
    return ()
end

@external
func disassemble{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, bitwise_ptr: BitwiseBuiltin*, range_check_ptr
    } (owner: felt, token_id: felt, fts_len: felt, fts: FTSpec*, nfts_len: felt, nfts: felt*):
    disassemble_(owner, token_id, fts_len, fts, nfts_len, nfts)
    return ()
end

@external
func transferOneNFT{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, bitwise_ptr: BitwiseBuiltin*, range_check_ptr
    } (sender: felt, recipient: felt, token_id: felt):
    ERC721_transferability.transferFrom_(sender, recipient, token_id)
    return ()
end
