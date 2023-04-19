use array::ArrayTrait;
use array::SpanTrait;
use traits::Into;
use traits::TryInto;
use option::OptionTrait;

const ANY_MATERIAL_ANY_COLOR: felt252 = 0;

// TODO: convert those to load from data
const shape_offset_cumulative: felt252 = 1;
const shape_offset_cumulative_end: felt252 = 1;
const shape_data: felt252 = 1;
const shape_data_end: felt252 = 1;
const nft_offset_cumulative: felt252 = 1;
const nft_offset_cumulative_end: felt252 = 1;
const nft_data: felt252 = 1;
const nft_data_end: felt252 = 1;

use briq_protocol::utils::check_gas;

use briq_protocol::utils; // import u256 -> felt

// For reference, see also cairo-based uncompression below.
#[derive(Copy, Drop)]
struct UncompressedShapeItem {
    material: felt252,
    color: felt252,
    x: felt252,
    y: felt252,
    z: felt252,
    nft_token_id: felt252,
}

use briq_protocol::types::FTSpec;
use briq_protocol::types::ShapeItem;

fn get_label_location(label: felt252) -> felt252 {
    return 1;
}

// Returns the number of shapes stored in the contract data. Remove 1 because that's boundaries.
fn _get_nb_shapes() -> felt252 {
    let _shape_offset_cumulative_start = get_label_location(shape_offset_cumulative);
    let _shape_offset_cumulative_end = get_label_location(shape_offset_cumulative_end);
    return _shape_offset_cumulative_end - _shape_offset_cumulative_start - 1;
}

// Returns the offsets for the i-th shape (starting from 0). End is exclusive.
fn _get_shape_offsets(i: felt252) -> (felt252, felt252) { //(start: felt252*, end: felt252*) {
    let _shape_offset_cumulative_start = get_label_location(shape_offset_cumulative);
    let loc = get_label_location(shape_data);
    return (
        loc + (_shape_offset_cumulative_start + i) * 2, //ShapeItem.SIZE,
        loc + (_shape_offset_cumulative_start + i + 1) * 2 //ShapeItem.SIZE
    );
}

// Returns the offset for the i-th nft (starting from 0). End is exclusive.
fn _get_nft_offsets(i: felt252) -> (felt252, felt252) { //(start: felt252*, end: felt252*) {
    let _nft_offset_cumulative_start = get_label_location(nft_offset_cumulative);
    let loc = get_label_location(nft_data);
    return (
        loc + _nft_offset_cumulative_start + i,
        loc + _nft_offset_cumulative_start + i + 1
    );
}

fn _shape(i: felt252) -> (Array::<ShapeItem>, Array::<felt252>) { //(shape_len: felt252, shape: ShapeItem*, nfts_len: felt252, nfts: felt252*
    let (_shape_data_start, _shape_data_end) = _get_shape_offsets(i);
    let (_nft_data_start, _nft_data_end) = _get_nft_offsets(i);

    let items = ArrayTrait::<ShapeItem>::new();
    let nfts = ArrayTrait::<felt252>::new();

    return (items, nfts);
}


//@view
fn get_local_index(global_index: felt252) -> felt252 {
    // TODO: parametrize on duck collection ID
    return (global_index - 345234829834) / (0x1000000000000000000000000000000000000000000000000) - 1;
}

//@view
fn shape_(global_index: felt252) -> (Array::<ShapeItem>, Array::<felt252>) { //(shape_len: felt252, shape: ShapeItem*, nfts_len: felt252, nfts: felt252*) {
    return _shape(get_local_index(global_index));
}

// Iterate through positions until we find the right one, incrementing the NFT counter so we return the correct ID.
fn _find_nft(x_y_z: felt252, mut data_shape: Array<ShapeItem>, mut data_nft: Array<felt252>) -> felt252 { //(token_id: felt252) {
    check_gas();
    let current_item = data_shape.pop_front().unwrap();
    if (current_item.x_y_z == x_y_z) {
        return data_nft.pop_front().unwrap();
    }
    let is_nft = current_item.color_nft_material & 0x100000000000000000000000000000000;
    if is_nft != 0 {
        data_nft.pop_front();
    }
    return _find_nft(x_y_z, data_shape, data_nft);
}


// Intended as mostly a 'debug' function, thus the use of local_index
//@view
fn decompress_data(data: ShapeItem, local_index: felt252) -> UncompressedShapeItem { //(data: UncompressedShapeItem) {
    let color = data.color_nft_material & 0x7ffffffffffffffffffffffffffff0000000000000000000000000000000000;//2 ** 251 - 1 - 2 ** 136 + 1);
    let material = data.color_nft_material & 0xffffffffffffffff;//2 ** 64 - 1);
    let x = data.x_y_z & 0x7ffffffffffffffffffffffffffffff00000000000000000000000000000000;//2 ** 251 - 1 - 2 ** 128 + 1);
    let y = data.x_y_z & 0xffffffffffffffff0000000000000000;//2 ** 128 - 1 - 2 ** 64 + 1);
    let z = data.x_y_z & 0xffffffffffffffff;//2 ** 64 - 1);
    
    let color = color / 0x10000000000000000000000000000000000; //2 ** 136,
    let x = x / 0x100000000000000000000000000000000 - 0x8000000000000000; //2 ** 128 - 0x8000000000000000,
    let y = y / 0x10000000000000000 - 0x8000000000000000; //2 ** 64 - 0x8000000000000000,
    let z = z - 0x8000000000000000;

    let is_nft = data.color_nft_material & 0x100000000000000000000000000000000;//bitwise_and(data.color_nft_material, 2 ** 128);
    if is_nft == 0 {
        return UncompressedShapeItem { material, color, x, y, z, nft_token_id: 0 };
    }

    let (data_shape, data_nfts) = _shape(local_index);
    let token_id = _find_nft(data.x_y_z, data_shape, data_nfts);
    return UncompressedShapeItem { material, color, x, y, z, nft_token_id: token_id };
}

// This is a complete check function. Takes a number of FT/NFTs, and a shape, and asserts that it all matches
// the shape currently stored in the contract.
//@view
fn check_shape_numbers_(global_index: felt252, ref shape: Span<ShapeItem>, ref fts: Span<FTSpec>, ref nfts: Span<felt252>) {
    //with_attr error_message("Wrong number of shape items") {
    let (data_start, data_end) = _get_shape_offsets(get_local_index(global_index));
    assert (shape.len().into() == (data_end - data_start) / 2, 'wrong nb shape');//ShapeItem.SIZE;

    //with_attr error_message("Wrong number of NFTs") {
    let (nft_start, nft_end) = _get_nft_offsets(get_local_index(global_index));
    assert(nfts.len().into() == nft_end - nft_start, 'wrong nb nft');

    // NB:
    // - This expects the NFTs to be sorted the same as the shape sorting,
    //   so in the same X/Y/Z order.
    // - We don't actually need to check the shape sorting or duplicate NFTs, because:
    //   - shape sorting would fail to match the target (which is sorted).
    //   - duplicated NFTs would fail to transfer.
    // - We need to make sure that the shape tokens match our numbers, so we count fungible tokens.
    //     To do that, we'll create a vector of quantities that we'll increment when iterating.
    //     For simplicity, we initialise it with the fts quantity, and decrement to 0, then just check that everything is 0.
    let qty = _initialize_qty(fts, ArrayTrait::<felt252>::new());
    let (data, data_nfts) = shape_(global_index);
    _check_shape_numbers_impl_(data.span(), data_nfts.span(), shape, fts, qty, nfts);
}

fn _initialize_qty(mut fts: Span<FTSpec>, mut qty: Array<felt252>) -> Array<felt252> {
    check_gas();
    if fts.len() == 0 {
        return qty;
    }
    qty.append(*(fts.pop_front().unwrap()).qty);
    return _initialize_qty(fts, qty);
}

fn _check_qty_are_correct(mut qty: Array<felt252>) {
    check_gas();
    if qty.len() == 0 {
        return ();
    }
    assert(qty.pop_front().unwrap() == 0, 'wrong qty');
    return _check_qty_are_correct(qty);
}

fn _check_shape_numbers_impl_(
    mut stored_shape: Span<ShapeItem>,
    mut stored_nfts: Span<felt252>,
    mut shape: Span<ShapeItem>,
    mut fts: Span<FTSpec>,
    mut qty: Array<felt252>,
    mut nfts: Span<felt252>,
) {
    check_gas();
    if shape.len() == 0 {
        //with_attr error_message("Wrong number of briqs in shape") {
        // At this point, if one of the quantities isn't 0, then we have a big problem.
        // (we know the length is correct by construction).
        _check_qty_are_correct(qty);
        assert(nfts.len() == 0, 'wrong nb nft');
        return ();
    }

    let storedShapeItem = *(stored_shape.pop_front().unwrap());
    let shapeItem = *(shape.pop_front().unwrap());

    // Shape length has been asserted identical, so we just need to check that the data is identical.
    //with_attr error_message("Shapes do not match") {
    if storedShapeItem.color_nft_material != ANY_MATERIAL_ANY_COLOR {
        assert(storedShapeItem.color_nft_material == shapeItem.color_nft_material, 'bad shape item')
    }
    assert(storedShapeItem.x_y_z == shapeItem.x_y_z, 'bad shape item');

    // Algorithm:
    // If the shape item is an nft, compare with the next nft in the list, if match, carry on.
    // Otherwise, decrement the corresponding FT quantity. This is O(n) because we must copy the whole vector.
    //is_le_felt252(2 ** 250 + 2**249, ((2**129-1) / 2**130) - (shape[0].color_nft_material / 2**130));
    let is_nft = shapeItem.color_nft_material & 0x100000000000000000000000000000000;
    if is_nft != 0 {
        // Check that the material matches.
        //with_attr error_message("Incorrect NFT") {
        let stored_nft_data = *(stored_nfts.pop_front().unwrap());
        let nft_data = *(nfts.pop_front().unwrap());
        assert(stored_nft_data == nft_data, 'bad nft');
        //let a = shape[0].color_nft_material - nfts[0];
        //let b = a / (2 ** 64);
        //let is_same_mat = is_le_felt252(b, 2 ** 187);
        //assert is_same_mat = 1;
        assert((shapeItem.color_nft_material & 0xffffffffffffffff) == (nft_data & 0xffffffffffffffff), 'not same mat');
        return _check_shape_numbers_impl_(stored_shape, stored_nfts, shape, fts, qty, nfts);
    } else {
        // Find the material
        // NB: using a bitwise here is somewhat balanced with the cairo steps & range comparisons,
        // and so it ends up being more gas efficient than doing the is_le_felt252 trick.
        let mat = shapeItem.color_nft_material & 0xffffffffffffffff; // bitwise_and(shape[0].color_nft_material, 2 ** 64 - 1);
        assert(mat != 0, 'bad shape item');
        // Decrement the appropriate counter
        let qty = _decrement_ft_qty(fts, mat, qty, ArrayTrait::<felt252>::new());
        return _check_shape_numbers_impl_(stored_shape, stored_nfts, shape, fts, qty, nfts);
    }
}

// We need to keep a counter for each material we run into.
// But because of immutability, we'll need to copy the full vector of materials every time.
// TODO: figure out if I can use cleverer typing, perhaps an array of array here (because that's what this is sorta).
fn _decrement_ft_qty(mut fts: Span<FTSpec>, material: felt252, mut qty_in: Array<felt252>, mut qty_out: Array<felt252>) -> Array<felt252> {
    check_gas();
    if fts.len() == 0 {
        // Ensure we found the material in case the user lied in the fts list.
        // material can't be 0 initially, as we check for that in the outer loop.
        //with_attr error_message("Material not found in FT list") {
        assert(material != 0, 'material not found');
        return qty_out;
    }
    let current_material = (*(fts.pop_front().unwrap())).token_id;
    if (material == current_material) {
        qty_out.append((qty_in.pop_front().unwrap()) - 1);
        // Switch to 0 to mark we found the material
        return _decrement_ft_qty(fts, 0, qty_in, qty_out);
    } else {
        qty_out.append(qty_in.pop_front().unwrap());
        return _decrement_ft_qty(fts, material, qty_in, qty_out);
    }
}
