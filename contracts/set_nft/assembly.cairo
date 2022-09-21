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

from contracts.set_nft.token_uri import tokenURI_, _setTokenURI, URI

from contracts.library_erc721.balance import _owner, _balance
from contracts.library_erc721.enumerability import ERC721_enumerability

from contracts.library_erc721.transferability import ERC721_transferability

from contracts.ecosystem.to_briq import (_briq_address,)
from contracts.ecosystem.to_attributes_registry import (_attributes_registry_address,)

from contracts.types import ShapeItem, FTSpec

from starkware.cairo.common.hash_state import (
    hash_init,
    hash_finalize,
    hash_update,
    hash_update_single,
)


@contract_interface
namespace IBriqContract {
    func transferFT_(sender: felt, recipient: felt, material: felt, qty: felt) {
    }
    func transferOneNFT_(sender: felt, recipient: felt, material: felt, briq_token_id: felt) {
    }
    func materialsOf_(owner: felt) -> (materials_len: felt, materials: felt*) {
    }
}

@contract_interface
namespace IAttributesRegistryContract {
    func wrap_(
        owner: felt,
        set_token_id: felt,
        attributes_registry_token_id: felt,
        shape_len: felt,
        shape: ShapeItem*,
        fts_len: felt,
        fts: FTSpec*,
        nfts_len: felt,
        nfts: felt*,
    ) {
    }
    func unwrap_(owner: felt, set_token_id: felt, attributes_registry_token_id: felt) {
    }
    func balanceOf_(owner: felt, token_id: felt) -> (balance: felt) {
    }
}

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

    ERC721_transferability._onTransfer(0, owner, token_id);
    URI.emit(uri_len, uri, token_id);

    return (token_id,);
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

    ERC721_transferability._onTransfer(owner, 0, token_id);
    return ();
}


func _check_briqs_and_attributes_are_zero{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    token_id: felt
) {
    // Check that we gave back all briqs (the user might attempt to lie).
    let (briq_addr) = _briq_address.read();
    let (mat_len, mat) = IBriqContract.materialsOf_(briq_addr, token_id);
    assert mat_len = 0;
    
    // Check that we no longer have any attributes active.
    let (attributes_registry_addr) = _attributes_registry_address.read();
    let (balance) = IAttributesRegistryContract.total_balance(attributes_registry_addr, token_id);
    assert balance = 0;
}

// The simple assembly function takes a list of briq tokens and transfers them to the set.
// The set then acts as a smart wallet.
@external
func assemble_{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, bitwise_ptr: BitwiseBuiltin*, range_check_ptr
}(
    owner: felt,
    token_id_hint: felt,
    uri_len: felt, uri: felt*,
    fts_len: felt, fts: FTSpec*,
    nfts_len: felt, nfts: felt*,
) {
    alloc_locals;

    let (token_id) = _create_token_(owner, token_id_hint, uri_len, uri);

    _transferFT(owner, token_id, fts_len, fts);
    _transferNFT(owner, token_id, nfts_len, nfts);

    return ();
}

// This assembly variant takes an attribute ID and attempts to assign this attribute to the set.
// This might fail if the set doesn't fit the attribute rules (see attributes_registry).
// To allow fancier rules, this variant takes a full 3D shape description.
// NB: we don't recreate the fts/nfts vector here, for efficiency.
// However, the code MUST check that the shape vector matches the fts/nfts passed.
// briq's booklet contract does this via the shape contract.
@external
func assemble_with_attribute_{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, bitwise_ptr: BitwiseBuiltin*, range_check_ptr
}(
    owner: felt,
    token_id_hint: felt,
    uri_len: felt, uri: felt*,
    fts_len: felt, fts: FTSpec*,
    nfts_len: felt, nfts: felt*,
    shape_len: felt, shape: ShapeItem*,
    attribute_id: felt,
) {
    alloc_locals;
    let (token_id) = _create_token_(owner, token_id_hint, uri_len, uri);

    _transferFT(owner, token_id, fts_len, fts);
    _transferNFT(owner, token_id, nfts_len, nfts);

    local pedersen_ptr: HashBuiltin* = pedersen_ptr;

    let (attributes_registry_address) = _attributes_registry_address.read();
    IAttributesRegistryContract.assign_attribute(
        attributes_registry_address,
        owner,
        token_id,
        attribute_id,
        shape_len,
        shape,
        fts_len,
        fts,
        nfts_len,
        nfts,
    );

    return ();
}

@external
func disassemble_{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    owner: felt, token_id: felt, fts_len: felt, fts: FTSpec*, nfts_len: felt, nfts: felt*
) {
    _destroy_token(owner, token_id);

    _transferFT(token_id, owner, fts_len, fts);
    _transferNFT(token_id, owner, nfts_len, nfts);

    _check_briqs_and_attributes_are_zero(token_id);
    return ();
}

@external
func disassemble_with_attribute_{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    owner: felt,
    token_id: felt,
    fts_len: felt,
    fts: FTSpec*,
    nfts_len: felt,
    nfts: felt*,
    attribute_id: felt,
) {
    _destroy_token(owner, token_id);

    _transferFT(token_id, owner, fts_len, fts);
    _transferNFT(token_id, owner, nfts_len, nfts);

    let (attributes_registry_address) = _attributes_registry_address.read();
    IAttributesRegistryContract.remove_attribute(attributes_registry_address, owner, token_id, attribute_id);

    _check_briqs_and_attributes_are_zero(token_id);

    return ();
}
