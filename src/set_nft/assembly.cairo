use briq_protocol::library_erc721::balance::Balance;
use briq_protocol::library_erc721::transferability::Transferability;

use briq_protocol::set_nft::token_uri::tokenURI_;

use briq_protocol::utilities::token_uri;
use briq_protocol::utilities::authorization::Auth::_only;

use briq_protocol::types::ShapeItem;
use briq_protocol::types::FTSpec;

use briq_protocol::ecosystem::to_briq::toBriq;
use briq_protocol::ecosystem::to_attributes_registry::toAttributesRegistry;


use starknet::contract_address;
use starknet::ContractAddress;
use traits::Into;
use traits::TryInto;
use array::ArrayTrait;
use array::SpanTrait;
use option::OptionTrait;

use briq_protocol::utils::check_gas;

#[abi]
trait IBriqContract {
    fn transferFT_(sender: felt252, recipient: felt252, material: felt252, qty: felt252);
    fn materialsOf_(owner: felt252) -> Array<felt252>;
}

#[abi]
trait IAttributesRegistryContract {
    fn total_balance(owner: felt252) -> felt252;

    fn assign_attributes(
        set_owner: ContractAddress,
        set_token_id: felt252,
        attributes: Array<felt252>,
        shape: Array<ShapeItem>,
        fts: Array<FTSpec>,
        nfts: Array<felt252>,
    );

    fn remove_attributes(
        set_owner: ContractAddress,
        set_token_id: felt252,
        attributes: Array<felt252>
    );
}

//###########
//###########
// Assembly/Disassembly

fn _transferFT(sender: felt252, recipient: felt252, mut fts: Span<FTSpec>) {
    check_gas();
    if fts.len() == 0 {
        return ();
    }
    let address = toBriq::get();
    let ftspec = *fts.pop_front().unwrap();
    IBriqContractDispatcher { contract_address: address.try_into().unwrap() } .transferFT_(
        sender, recipient, ftspec.token_id, ftspec.qty
    );
    return _transferFT(sender, recipient, fts);
}

// To prevent people from generating collisions, we need the token_id to be random.
// However, we need it to be predictable for good UI.
// The solution adopted is to hash a hint. Our security becomes the chain hash security.
// Hash on the # of briqs to avoid people being able to 'game' off-chain latency,
// we had issues where people regenerated sets with the wrong # of briqs shown on marketplaces before a refresh.
fn _hashTokenId(
    owner: felt252,
    token_id_hint: felt252,
    nb_briqs: felt252,
) -> felt252 { //(token_id: felt252) {
    let hash = pedersen(0, owner);
    let hash = pedersen(hash, token_id_hint);
    let hash = pedersen(hash, nb_briqs);
    assert(false, 'TODO');
    hash
}


fn _create_token_(owner: felt252, token_id_hint: felt252, nb_briqs: felt252) -> felt252 {
    // TODO: consider allowing approved operators?
    _only(owner.try_into().unwrap());

    assert(owner != 0, 'Bad owner');

    let token_id = _hashTokenId(owner, token_id_hint, nb_briqs);

    let curr_owner = Balance::_owner::read(token_id);
    assert(curr_owner == 0, 'Token already exists');
    Balance::_owner::write(token_id, owner);

    Balance::_increaseBalance(owner);
    
    // TODO: figure out if I want to reimplement this
    //ERC721_enumerability._setTokenByOwner(owner, token_id, 0);

    Transferability::Transfer(0, owner, token_id.into());

    token_uri::URI(tokenURI_(token_id), token_id.into());

    token_id
}


fn _destroy_token(owner: felt252, token_id: felt252) {
    _only(owner.try_into().unwrap());

    assert(token_id != 0, 'Bad input');
    assert(owner != 0, 'Bad input');

    let curr_owner = Balance::_owner::read(token_id);
    assert(curr_owner == owner, 'Not owner');
    Balance::_owner::write(token_id, 0);

    Balance::_decreaseBalance(owner);

    //ERC721_enumerability._unsetTokenByOwner(owner, token_id);

    Transferability::Transfer(owner, 0, token_id.into());
}


fn _check_briqs_and_attributes_are_zero(token_id: felt252) {
    // Check that we gave back all briqs (the user might attempt to lie).
    let mats = IBriqContractDispatcher { contract_address: toBriq::get().try_into().unwrap()
        }.materialsOf_(token_id);
    assert(mats.len() == 0, 'Set still owns briqs');
    
    // Check that we no longer have any attributes active.
    let balance = IAttributesRegistryContractDispatcher { contract_address: toAttributesRegistry::get().try_into().unwrap()
        }.total_balance(token_id);
    assert(balance == 0, 'Set still attributed');
}

// Assembly takes a list of attribute IDs and attempts to assign these attributes to the set.
// This might fail if the set doesn't fit the attribute rules (see attributes_registry).
// To allow fancier rules, this variant takes a full 3D shape description.
// NB: we don't recreate the fts/nfts vector here, for efficiency.
// However, the code MUST check that the shape vector matches the fts/nfts passed, if used.
// briq's booklet contract does this via the shape contract.
//@external
fn assemble_(
    owner: felt252,
    token_id_hint: felt252,
    //name: Array<felt252>,
    //description: Array<felt252>,
    fts: Array<FTSpec>,
    nfts: Array<felt252>,
    shape: Array<ShapeItem>,
    attributes: Array<felt252>,
) {
    let token_id = _create_token_(owner, token_id_hint, shape.len().into());

    _transferFT(owner, token_id, fts.span());

    IAttributesRegistryContractDispatcher { contract_address: toAttributesRegistry::get().try_into().unwrap() }.assign_attributes(
        owner.try_into().unwrap(),
        token_id,
        attributes,
        shape,
        fts,
        nfts,
    );
}

//@external
fn disassemble_(
    owner: felt252,
    token_id: felt252,
    fts: Array<FTSpec>,
    nfts: Array<felt252>,
    attributes: Array<felt252>,
) {
    _destroy_token(owner, token_id);

    _transferFT(token_id, owner, fts.span());

    IAttributesRegistryContractDispatcher { contract_address: toAttributesRegistry::get().try_into().unwrap() }.remove_attributes(
        owner.try_into().unwrap(),
        token_id,
        attributes);

    _check_briqs_and_attributes_are_zero(token_id);
}
