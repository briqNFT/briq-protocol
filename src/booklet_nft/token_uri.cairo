use traits::TryInto;
use option::OptionTrait;

use starknet::class_hash;

use briq_protocol::utils;

use briq_protocol::types::ShapeItem;
use briq_protocol::types::FTSpec;

use briq_protocol::ecosystem::genesis_collection::GENESIS_COLLECTION;

#[abi]
trait IShapeContract {
    fn shape_(i: felt252) -> (Array::<ShapeItem>, Array::<felt252>);
}

#[contract]
mod toShapeContract {
    struct Storage {
        _shape_contract: LegacyMap<felt252, felt252>,
    }

    //#[view]
    fn get_shape_contract_(token_id: felt252) -> felt252 { //(address: felt252) {
        return _shape_contract::read(token_id);
    }
}

//@view
fn get_shape_(token_id: felt252) -> (Array::<ShapeItem>, Array::<felt252>) {
    let addr = toShapeContract::_shape_contract::read(token_id);
    return IShapeContractLibraryDispatcher { class_hash: addr.try_into().unwrap() }.shape_((token_id - GENESIS_COLLECTION) / 0x1000000000000000000000000000000000000000000000000);//2**192);
}

// @view
fn tokenURI_(token_id: felt252) -> Array<felt252> {
    briq_protocol::utilities::token_uri::_getUrl(
        token_id,
        'https://api.briq.construction',
        '/v1/uri/booklet/',
        'starknet-mainnet/',
        '.json',
    )
}
