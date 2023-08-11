use array::ArrayTrait;

#[derive(Drop, Copy, Serde)]
struct BoxData {
    briq_1: felt252,  // nb of briqs of material 0x1
    briq_3: felt252,  // nb of briqs of material 0x3
    briq_4: felt252,  // nb of briqs of material 0x4
    briq_5: felt252,  // nb of briqs of material 0x5
    briq_6: felt252,  // nb of briqs of material 0x6
    shape_class_hash: felt252,  // Class hash of the matching shape contract
}

//@view
fn get_box_data(token_id: felt252) -> BoxData { //(data: BoxData) {
    //let box: BoxData* = alloc();
    //let (briq_data) = get_label_location(briq_data_start);
    //memcpy(box, briq_data + 5 * (token_id - 1), 5);
    //let (shape_data) = get_label_location(shape_data_start);
    //memcpy(box + 5, shape_data + (token_id - 1), 1);
    assert(false, 'TODO');
    BoxData { briq_1: 0, briq_3: 0, briq_4: 0, briq_5: 0, briq_6: 0, shape_class_hash: 0 }
}

//@view
fn get_box_nb(nb: felt252) -> felt252 {
    //let (_start) = get_label_location(shape_data_start);
    //let (_end) = get_label_location(shape_data_end);
    //let res = _end - _start;
    //return (res,);
    assert(false, 'TODO');
    0
}

// @view
fn tokenURI_(token_id: felt252) -> Array<felt252> {
    briq_protocol::utilities::token_uri::_getUrl(
        token_id,
        'https://api.briq.construction',
        '/v1/uri/box/',
        'starknet-mainnet/',
        '.json',
    )
}
