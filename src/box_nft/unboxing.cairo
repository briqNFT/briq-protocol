use traits::Into;
use traits::TryInto;
use option::OptionTrait;

use array::ArrayTrait;

use starknet::contract_address;

use briq_protocol::library_erc1155::transferability::Transferability;
use briq_protocol::library_erc1155::balance::Balance;
use briq_protocol::utils::GetCallerAddress;
use briq_protocol::ecosystem::to_booklet::toBooklet;
use briq_protocol::ecosystem::to_briq::toBriq;
use briq_protocol::ecosystem::genesis_collection::GENESIS_COLLECTION;
use briq_protocol::constants;

use briq_protocol::box_nft::token_uri::BoxData;

#[abi]
trait IBookletContract {
    fn mint_(owner: felt252, token_id: felt252, shape_contract: felt252);
}

#[abi]
trait IBriqContract {
    fn mintFT_(owner: felt252, material: felt252, qty: felt252);
}

// Unbox burns the box NFT, and mints briqs & attributes_registry corresponding to the token URI.
//@external
fn unbox_(owner: felt252, token_id: felt252) {
    Balance::_decreaseBalance(owner, token_id, 1);
    // At this point token_id cannot be 0 any more

    let caller = GetCallerAddress();
    // Only the owner may unbox their box.
    assert(owner == caller, 'Not owner');
    Transferability::TransferSingle(caller, owner, 0, token_id.into(), 1.into());

    _unbox_mint(owner, token_id);
}

fn _unbox_mint(owner: felt252, token_id: felt252) {
    //let (_shape_data_start) = get_label_location(shape_data_start);
    //let shape_contract = [cast(_shape_data_start, felt252*) + token_id - 1];
    assert(false, 'TODO');
    let shape_contract = 0;
    IBookletContractDispatcher { contract_address: toBooklet::get().try_into().unwrap() } .mint_(owner, token_id * constants::c2_192 + GENESIS_COLLECTION, shape_contract);

    //let (_briq_data_start) = get_label_location(briq_data_start);
    //let (briq_addr) = _briq_address.read();
    assert(false, 'TODO');
    let briq_addr = toBriq::get();
    _maybe_mint_briq(owner, briq_addr, ArrayTrait::<felt252>::new(), token_id, 1, 0);
    //_maybe_mint_briq(owner, briq_addr, cast(_briq_data_start, felt252*), token_id, 3, 1);
    //_maybe_mint_briq(owner, briq_addr, cast(_briq_data_start, felt252*), token_id, 4, 2);
    //_maybe_mint_briq(owner, briq_addr, cast(_briq_data_start, felt252*), token_id, 5, 3);
    // TODO -> NFT briqs
    // let (amnt) = [cast(_briq_data_start, felt252*) + 1]
    // IBriqContract.mintFT_(briq_addr, owner, 0x1, amnt)

    return ();
}

// token_id acts as the global data offset, where offset is the inner-data offset.
fn _maybe_mint_briq(owner: felt252, briq_addr: felt252, briq_data: Array<felt252>, token_id: felt252, material: felt252, offset: felt252,
) {
    // sizeof<BoxData>
    let amnt = *briq_data[(token_id * 6 + offset).try_into().unwrap()];
    if amnt != 0 {
        IBriqContractDispatcher { contract_address: briq_addr.try_into().unwrap() }.mintFT_(owner, material, amnt);
    }
}
