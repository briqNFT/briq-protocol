
#[abi]
trait IShapeContract {
    fn _shape(i: felt252) -> (Array::<ShapeItem>, Array::<felt252>);
    fn check_shape_numbers_(global_index: felt252, shape: Array<ShapeItem>, fts: Array<FTSpec>, nfts: Array<felt252>);
}

use starknet::class_hash;
use traits::TryInto;
use option::OptionTrait;

use briq_protocol::utils;
use briq_protocol::booklet_nft::token_uri::toShapeContract::get_shape_contract_;
use briq_protocol::types::ShapeItem;
use briq_protocol::types::FTSpec;
use briq_protocol::ecosystem::to_attributes_registry::toAttributesRegistry::_onlyAttributesRegistry;

use briq_protocol::library_erc1155::transferability::Transferability;
use briq_protocol::ecosystem::genesis_collection::GENESIS_COLLECTION;
//###########
//###########

fn _check_shape(
    attribute_id: felt252,
    shape: Array<ShapeItem>,
    fts: Array<FTSpec>,
    nfts: Array<felt252>,
) {
    // Check that the shape matches the passed data
    let addr = get_shape_contract_(attribute_id);

    // TEMP HACK because my original code hardcoded GENESIS_COLLECTION here.
    // Need to update the shape contracts that the booklets point to.
    let coll = (attribute_id - GENESIS_COLLECTION) / 0x1000000000000000000000000000000000000000000000000;
    //let is_genesis = is_le_felt252(coll, 2**63);
    let is_genesis = coll & 0xffffffffffffffff;
    if (is_genesis == GENESIS_COLLECTION) {
        IShapeContractLibraryDispatcher { class_hash: addr.try_into().unwrap() }.check_shape_numbers_(
            coll, shape, fts, nfts
        );
    } else {
        IShapeContractLibraryDispatcher { class_hash: addr.try_into().unwrap() }.check_shape_numbers_(
            attribute_id, shape, fts, nfts
        );
    }
    return ();
}

//@external
fn assign_attribute(
    owner: felt252,
    set_token_id: felt252,
    attribute_id: felt252,
    shape: Array<ShapeItem>,
    fts: Array<FTSpec>,
    nfts: Array<felt252>,
) {    
    _onlyAttributesRegistry();

    _check_shape(attribute_id, shape, fts, nfts);

    // Transfer the booklet to the set.
    // The owner of the set must also be the owner of the booklet.
    Transferability::_transfer(owner, set_token_id, attribute_id, 1);
}

//@external
fn remove_attribute(
    owner: felt252,
    set_token_id: felt252,
    attribute_id: felt252,
) {
    _onlyAttributesRegistry();

    // Give the booklet back to the original set owner.
    Transferability::_transfer(set_token_id, owner, attribute_id, 1);
}
