%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin, SignatureBuiltin, BitwiseBuiltin
from starkware.starknet.common.syscalls import get_caller_address
from starkware.cairo.common.math import (
    assert_nn_le,
    assert_lt,
    assert_le,
    assert_not_zero,
    assert_lt_felt,
    unsigned_div_rem,
)
from starkware.cairo.common.math_cmp import is_le_felt
from starkware.cairo.common.registers import get_fp_and_pc
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.bool import FALSE, TRUE
from starkware.starknet.common.syscalls import call_contract

from starkware.cairo.common.bitwise import bitwise_and

from contracts.utilities.authorization import _only, _onlyAdmin

from contracts.set_erc721.token_uri import tokenURI_, _setTokenURI, URI

from contracts.library_erc721.balance import _owner, _balance
from contracts.library_erc721.enumerability import ERC721_enumerability

from contracts.library_erc721.transferability_library import ERC721_lib_transfer

from contracts.set_erc721.link_to_ecosystem import (
    _briq_address,
    _booklet_address,
    IBriqContract,
    IBookletContract,
)

from contracts.types import ShapeItem, FTSpec

from starkware.cairo.common.hash_state import (
    hash_init,
    hash_finalize,
    hash_update,
    hash_update_single,
)

//###########
//###########
// Assembly/Disassembly

func _transferFT{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    sender: felt, recipient: felt, index: felt, fts: FTSpec*
) {
    if (index == 0) {
        return ();
    }
    let (address) = _briq_address.read();
    IBriqContract.transferFT_(
        address, sender, recipient, fts[index - 1].token_id, fts[index - 1].qty
    );
    return _transferFT(sender, recipient, index - 1, fts);
}

func _transferNFT{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    sender: felt, recipient: felt, index: felt, nfts: felt*
) {
    if (index == 0) {
        return ();
    }
    let (address) = _briq_address.read();
    let (uid, material) = unsigned_div_rem(nfts[index - 1], 2 ** 64);
    IBriqContract.transferOneNFT_(address, sender, recipient, material, nfts[index - 1]);
    return _transferNFT(sender, recipient, index - 1, nfts);
}

// To prevent people from generating collisions, we need the token_id to be random.
// However, we need it to be predictable for good UI.
// The solution adopted is to hash a hint. Our security becomes the chain hash security.
// To be able to store e.g. sha-256 IPFS data in the tokenURI, we reserve a few bits
// off the end for extra-URI storage when minting.
func _hashTokenId{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, bitwise_ptr: BitwiseBuiltin*, range_check_ptr
}(owner: felt, token_id_hint: felt, uri_len: felt, uri: felt*) -> (token_id: felt) {
    let hash_ptr = pedersen_ptr;
    with hash_ptr {
        let (hash_state_ptr) = hash_init();
        let (hash_state_ptr) = hash_update_single(hash_state_ptr, owner);
        let (hash_state_ptr) = hash_update_single(hash_state_ptr, token_id_hint);
        let (token_id) = hash_finalize(hash_state_ptr);
        // The magic number is (2**251 - 1) - (2**59 - 1), which leaves the top 192 bits for the token_id.
        let (token_id) = bitwise_and(
            token_id, 3618502788666131106986593281521497120414687020801267626232473039494981877760
        );
    }
    let pedersen_ptr = hash_ptr;
    let (token_id) = _maybeAddPartOfTokenUri(token_id, uri_len, uri);
    return (token_id,);
}

// If the token URI is two items long, and the second item fits in the remainder 59 bits,
// then store it there instead of writing another storage variable.
// NB: this will become an integral part of the token_id, so that even if the URI changes
// in the future, it won't change. As such, it's only a minting-time optimisation.
func _maybeAddPartOfTokenUri{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, bitwise_ptr: BitwiseBuiltin*, range_check_ptr
}(token_id: felt, uri_len: felt, uri: felt*) -> (token_id: felt) {
    if (uri_len == 2) {
        let (rem) = bitwise_and(uri[1], 2 ** 59 - 1);
        if (uri[1] == rem) {
            let token_id = token_id + uri[1];
            return (token_id,);
        }
        return (token_id,);
    }
    return (token_id,);
}

@external
func assemble_{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, bitwise_ptr: BitwiseBuiltin*, range_check_ptr
}(
    owner: felt,
    token_id_hint: felt,
    fts_len: felt,
    fts: FTSpec*,
    nfts_len: felt,
    nfts: felt*,
    uri_len: felt,
    uri: felt*,
) {
    alloc_locals;

    let (token_id) = _create_token_(owner, token_id_hint, uri_len, uri);

    _transferFT(owner, token_id, fts_len, fts);
    _transferNFT(owner, token_id, nfts_len, nfts);

    return ();
}

from starkware.cairo.common.memcpy import memcpy

@external
func assemble_with_booklet_{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, bitwise_ptr: BitwiseBuiltin*, range_check_ptr
}(
    owner: felt,
    token_id_hint: felt,
    uri_len: felt,
    uri: felt*,
    fts_len: felt,
    fts: FTSpec*,
    nfts_len: felt,
    nfts: felt*,
    booklet_token_id: felt,
    shape_len: felt,
    shape: ShapeItem*,
) {
    alloc_locals;
    let (token_id) = _create_token_(owner, token_id_hint, uri_len, uri);

    _transferFT(owner, token_id, fts_len, fts);
    _transferNFT(owner, token_id, nfts_len, nfts);

    local pedersen_ptr: HashBuiltin* = pedersen_ptr;

    let (booklet_address) = _booklet_address.read();
    // Call the booklet contract to validate the shape (and wrap it inside ourselves)
    IBookletContract.wrap_(
        booklet_address,
        owner,
        token_id,
        booklet_token_id,
        shape_len,
        shape,
        fts_len,
        fts,
        nfts_len,
        nfts,
    );

    // Assert balance in booklet contract ?

    return ();
}

func _create_token_{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, bitwise_ptr: BitwiseBuiltin*, range_check_ptr
}(owner: felt, token_id_hint: felt, uri_len: felt, uri: felt*) -> (token_id: felt) {
    alloc_locals;

    // TODO: consider allowing approved operators?
    _only(owner);

    assert_not_zero(owner);

    let (local token_id: felt) = _hashTokenId(owner, token_id_hint, uri_len, uri);

    let (curr_owner) = _owner.read(token_id);
    assert curr_owner = 0;
    _owner.write(token_id, owner);

    let (balance) = _balance.read(owner);
    _balance.write(owner, balance + 1);

    ERC721_enumerability._setTokenByOwner(owner, token_id, 0);

    _setTokenURI(TRUE, token_id, uri_len, uri);

    ERC721_lib_transfer._onTransfer(0, owner, token_id);
    URI.emit(uri_len, uri, token_id);

    return (token_id,);
}

@external
func disassemble_{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    owner: felt, token_id: felt, fts_len: felt, fts: FTSpec*, nfts_len: felt, nfts: felt*
) {
    _destroy_token(owner, token_id);

    _transferFT(token_id, owner, fts_len, fts);
    _transferNFT(token_id, owner, nfts_len, nfts);

    // Check that we sucessfully gave back all wrapped items.
    let (briq_addr) = _briq_address.read();
    let (mat_len, mat) = IBriqContract.materialsOf_(briq_addr, token_id);
    assert mat_len = 0;
    let (booklet_addr) = _booklet_address.read();
    let (balance) = IBookletContract.balanceOf_(booklet_addr, owner, token_id);
    assert balance = 0;
    // TODO: add generic support.

    return ();
}

@external
func disassemble_with_booklet_{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    owner: felt,
    token_id: felt,
    fts_len: felt,
    fts: FTSpec*,
    nfts_len: felt,
    nfts: felt*,
    booklet_token_id: felt,
) {
    _destroy_token(owner, token_id);

    _transferFT(token_id, owner, fts_len, fts);
    _transferNFT(token_id, owner, nfts_len, nfts);

    let (booklet_address) = _booklet_address.read();
    IBookletContract.unwrap_(booklet_address, owner, token_id, booklet_token_id);

    // Check that we sucessfully gave back all wrapped items.
    let (briq_addr) = _briq_address.read();
    let (mat_len, mat) = IBriqContract.materialsOf_(briq_addr, token_id);
    assert mat_len = 0;
    let (booklet_addr) = _booklet_address.read();
    let (balance) = IBookletContract.balanceOf_(booklet_addr, owner, token_id);
    assert balance = 0;
    // TODO: add generic support.

    return ();
}

func _destroy_token{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    owner: felt, token_id: felt
) {
    alloc_locals;
    _only(owner);

    assert_not_zero(token_id);
    assert_not_zero(owner);

    let (local curr_owner) = _owner.read(token_id);
    assert curr_owner = owner;
    _owner.write(token_id, 0);

    let (balance) = _balance.read(owner);
    _balance.write(owner, balance - 1);

    ERC721_enumerability._unsetTokenByOwner(owner, token_id);

    ERC721_lib_transfer._onTransfer(owner, 0, token_id);
    return ();
}
