use array::ArrayTrait;
use array::SpanTrait;

use debug::PrintTrait;

const ADDRESS: felt252 = 0x1234;

use briq_protocol::shape::shape_store;

#[test]
#[available_gas(999999)]
fn test_decompress_shape() {
    let color_nft_material = 0x233966323835610000000000000000000000000000000001;
    let x_y_z = 0x7ffffffffffffffe80000000000000008000000000000002;
    let decompressed = shape_store::decompress_data(shape_store::ShapeItem { color_nft_material, x_y_z }, 0);
    assert(decompressed.material == 1, 'Bad material');
    assert(decompressed.color == 9914735276864865, 'Bad color'); // #9f285a
    assert(decompressed.material == 1, 'Bad material');
    assert(decompressed.x == -2, 'Bad x');
    assert(decompressed.y == 0, 'Bad y');
    assert(decompressed.z == 2, 'Bad z');
    assert(decompressed.nft_token_id == 0, 'Bad NFT');
}
