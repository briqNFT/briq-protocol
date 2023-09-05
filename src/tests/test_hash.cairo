use array::{ArrayTrait, SpanTrait};
use briq_protocol::types::{FTSpec, PackedShapeItem, ShapePacking, ShapeItem};

use briq_protocol::attributes::shape_hasher::hash_shape;

use debug::PrintTrait;


#[test]
#[available_gas(20000)]
fn test_declare_shape_10_cost() {
    let shape = test_shape_10();
}

#[test]
#[available_gas(100000)]
fn test_declare_shape_50_cost() {
    let shape = test_shape_50();
}

#[test]
#[available_gas(200000)]
fn test_declare_shape_100_cost() {
    let shape = test_shape_100();
}


#[test]
#[available_gas(380000)]
fn test_hash_shape_10() {
    let fts = array![FTSpec { token_id: 1, qty: 10 }];
    let shape = test_shape_10();
    let hash = hash_shape(fts.span(), shape);

    // 'hash'.print();
    // hash.print();

    assert(
        hash == 0x7eb51e6cdc6a954a9e2b556e5422ff24d2254e42e93aa1ede311dcb305434c7, 'invalid hash'
    );
}


// #[test]
// #[available_gas(1700000)]
// fn test_hash_shape_50() {
//     let fts = array![FTSpec { token_id: 1, qty: 50 }];
//     let shape = test_shape_50();
//     let hash = hash_shape(fts.span(), shape);

//     'test_hash_shape_50'.print();
//     hash.print();

//     assert(
//         hash == 0x7a9065424690b5326eafa225b5f05eac77e82952170ccb1998903c2019780e7, 'invalid hash'
//     );
// }

// #[test]
// #[available_gas(3000000)]
// fn test_hash_shape_100() {
//     let fts = array![FTSpec { token_id: 1, qty: 100 }];
//     let shape = test_shape_100();
//     let hash = hash_shape(fts.span(), shape);

//     assert(
//         hash == 0x448c76cf59a3eefec6859fbfe51fd775ed3dff5b6c0d032692ed738cf214e41, 'invalid hash'
//     );
// }

//
// Test Data
//

fn test_shape_10() -> Span<PackedShapeItem> {
    array![
        ShapePacking::pack(ShapeItem { color: '#ffaaff', material: 1, x: 2, y: 4, z: -2 }),
        ShapePacking::pack(ShapeItem { color: '#ffaaff', material: 1, x: 3, y: 4, z: -2 }),
        ShapePacking::pack(ShapeItem { color: '#ffaaff', material: 1, x: 4, y: 4, z: -2 }),
        ShapePacking::pack(ShapeItem { color: '#ffaaff', material: 1, x: 5, y: 4, z: -2 }),
        ShapePacking::pack(ShapeItem { color: '#ffaaff', material: 1, x: 6, y: 4, z: -2 }),
        ShapePacking::pack(ShapeItem { color: '#ffaaff', material: 1, x: 7, y: 4, z: -2 }),
        ShapePacking::pack(ShapeItem { color: '#ffaaff', material: 1, x: 8, y: 4, z: -2 }),
        ShapePacking::pack(ShapeItem { color: '#ffaaff', material: 1, x: 9, y: 4, z: -2 }),
        ShapePacking::pack(ShapeItem { color: '#ffaaff', material: 1, x: 10, y: 4, z: -2 }),
        ShapePacking::pack(ShapeItem { color: '#ffaaff', material: 1, x: 11, y: 4, z: -2 }),
    ]
        .span()
}

fn test_shape_50() -> Span<PackedShapeItem> {
    array![
        ShapePacking::pack(ShapeItem { color: '#ffaaff', material: 1, x: 2, y: 4, z: -2 }),
        ShapePacking::pack(ShapeItem { color: '#ffaaff', material: 1, x: 3, y: 4, z: -2 }),
        ShapePacking::pack(ShapeItem { color: '#ffaaff', material: 1, x: 4, y: 4, z: -2 }),
        ShapePacking::pack(ShapeItem { color: '#ffaaff', material: 1, x: 5, y: 4, z: -2 }),
        ShapePacking::pack(ShapeItem { color: '#ffaaff', material: 1, x: 6, y: 4, z: -2 }),
        ShapePacking::pack(ShapeItem { color: '#ffaaff', material: 1, x: 7, y: 4, z: -2 }),
        ShapePacking::pack(ShapeItem { color: '#ffaaff', material: 1, x: 8, y: 4, z: -2 }),
        ShapePacking::pack(ShapeItem { color: '#ffaaff', material: 1, x: 9, y: 4, z: -2 }),
        ShapePacking::pack(ShapeItem { color: '#ffaaff', material: 1, x: 10, y: 4, z: -2 }),
        ShapePacking::pack(ShapeItem { color: '#ffaaff', material: 1, x: 11, y: 4, z: -2 }),
        //
        ShapePacking::pack(ShapeItem { color: '#ffaaff', material: 1, x: 2, y: 4, z: -2 }),
        ShapePacking::pack(ShapeItem { color: '#ffaaff', material: 1, x: 3, y: 4, z: -2 }),
        ShapePacking::pack(ShapeItem { color: '#ffaaff', material: 1, x: 4, y: 4, z: -2 }),
        ShapePacking::pack(ShapeItem { color: '#ffaaff', material: 1, x: 5, y: 4, z: -2 }),
        ShapePacking::pack(ShapeItem { color: '#ffaaff', material: 1, x: 6, y: 4, z: -2 }),
        ShapePacking::pack(ShapeItem { color: '#ffaaff', material: 1, x: 7, y: 4, z: -2 }),
        ShapePacking::pack(ShapeItem { color: '#ffaaff', material: 1, x: 8, y: 4, z: -2 }),
        ShapePacking::pack(ShapeItem { color: '#ffaaff', material: 1, x: 9, y: 4, z: -2 }),
        ShapePacking::pack(ShapeItem { color: '#ffaaff', material: 1, x: 10, y: 4, z: -2 }),
        ShapePacking::pack(ShapeItem { color: '#ffaaff', material: 1, x: 11, y: 4, z: -2 }),
        //
        ShapePacking::pack(ShapeItem { color: '#ffaaff', material: 1, x: 2, y: 4, z: -2 }),
        ShapePacking::pack(ShapeItem { color: '#ffaaff', material: 1, x: 3, y: 4, z: -2 }),
        ShapePacking::pack(ShapeItem { color: '#ffaaff', material: 1, x: 4, y: 4, z: -2 }),
        ShapePacking::pack(ShapeItem { color: '#ffaaff', material: 1, x: 5, y: 4, z: -2 }),
        ShapePacking::pack(ShapeItem { color: '#ffaaff', material: 1, x: 6, y: 4, z: -2 }),
        ShapePacking::pack(ShapeItem { color: '#ffaaff', material: 1, x: 7, y: 4, z: -2 }),
        ShapePacking::pack(ShapeItem { color: '#ffaaff', material: 1, x: 8, y: 4, z: -2 }),
        ShapePacking::pack(ShapeItem { color: '#ffaaff', material: 1, x: 9, y: 4, z: -2 }),
        ShapePacking::pack(ShapeItem { color: '#ffaaff', material: 1, x: 10, y: 4, z: -2 }),
        ShapePacking::pack(ShapeItem { color: '#ffaaff', material: 1, x: 11, y: 4, z: -2 }),
        //
        ShapePacking::pack(ShapeItem { color: '#ffaaff', material: 1, x: 2, y: 4, z: -2 }),
        ShapePacking::pack(ShapeItem { color: '#ffaaff', material: 1, x: 3, y: 4, z: -2 }),
        ShapePacking::pack(ShapeItem { color: '#ffaaff', material: 1, x: 4, y: 4, z: -2 }),
        ShapePacking::pack(ShapeItem { color: '#ffaaff', material: 1, x: 5, y: 4, z: -2 }),
        ShapePacking::pack(ShapeItem { color: '#ffaaff', material: 1, x: 6, y: 4, z: -2 }),
        ShapePacking::pack(ShapeItem { color: '#ffaaff', material: 1, x: 7, y: 4, z: -2 }),
        ShapePacking::pack(ShapeItem { color: '#ffaaff', material: 1, x: 8, y: 4, z: -2 }),
        ShapePacking::pack(ShapeItem { color: '#ffaaff', material: 1, x: 9, y: 4, z: -2 }),
        ShapePacking::pack(ShapeItem { color: '#ffaaff', material: 1, x: 10, y: 4, z: -2 }),
        ShapePacking::pack(ShapeItem { color: '#ffaaff', material: 1, x: 11, y: 4, z: -2 }),
        //
        ShapePacking::pack(ShapeItem { color: '#ffaaff', material: 1, x: 2, y: 4, z: -2 }),
        ShapePacking::pack(ShapeItem { color: '#ffaaff', material: 1, x: 3, y: 4, z: -2 }),
        ShapePacking::pack(ShapeItem { color: '#ffaaff', material: 1, x: 4, y: 4, z: -2 }),
        ShapePacking::pack(ShapeItem { color: '#ffaaff', material: 1, x: 5, y: 4, z: -2 }),
        ShapePacking::pack(ShapeItem { color: '#ffaaff', material: 1, x: 6, y: 4, z: -2 }),
        ShapePacking::pack(ShapeItem { color: '#ffaaff', material: 1, x: 7, y: 4, z: -2 }),
        ShapePacking::pack(ShapeItem { color: '#ffaaff', material: 1, x: 8, y: 4, z: -2 }),
        ShapePacking::pack(ShapeItem { color: '#ffaaff', material: 1, x: 9, y: 4, z: -2 }),
        ShapePacking::pack(ShapeItem { color: '#ffaaff', material: 1, x: 10, y: 4, z: -2 }),
        ShapePacking::pack(ShapeItem { color: '#ffaaff', material: 1, x: 11, y: 4, z: -2 }),
    ]
        .span()
}


fn test_shape_100() -> Span<PackedShapeItem> {
    array![
        ShapePacking::pack(ShapeItem { color: '#ffaaff', material: 1, x: 2, y: 4, z: -2 }),
        ShapePacking::pack(ShapeItem { color: '#ffaaff', material: 1, x: 3, y: 4, z: -2 }),
        ShapePacking::pack(ShapeItem { color: '#ffaaff', material: 1, x: 4, y: 4, z: -2 }),
        ShapePacking::pack(ShapeItem { color: '#ffaaff', material: 1, x: 5, y: 4, z: -2 }),
        ShapePacking::pack(ShapeItem { color: '#ffaaff', material: 1, x: 6, y: 4, z: -2 }),
        ShapePacking::pack(ShapeItem { color: '#ffaaff', material: 1, x: 7, y: 4, z: -2 }),
        ShapePacking::pack(ShapeItem { color: '#ffaaff', material: 1, x: 8, y: 4, z: -2 }),
        ShapePacking::pack(ShapeItem { color: '#ffaaff', material: 1, x: 9, y: 4, z: -2 }),
        ShapePacking::pack(ShapeItem { color: '#ffaaff', material: 1, x: 10, y: 4, z: -2 }),
        ShapePacking::pack(ShapeItem { color: '#ffaaff', material: 1, x: 11, y: 4, z: -2 }),
        //
        ShapePacking::pack(ShapeItem { color: '#ffaaff', material: 1, x: 2, y: 4, z: -2 }),
        ShapePacking::pack(ShapeItem { color: '#ffaaff', material: 1, x: 3, y: 4, z: -2 }),
        ShapePacking::pack(ShapeItem { color: '#ffaaff', material: 1, x: 4, y: 4, z: -2 }),
        ShapePacking::pack(ShapeItem { color: '#ffaaff', material: 1, x: 5, y: 4, z: -2 }),
        ShapePacking::pack(ShapeItem { color: '#ffaaff', material: 1, x: 6, y: 4, z: -2 }),
        ShapePacking::pack(ShapeItem { color: '#ffaaff', material: 1, x: 7, y: 4, z: -2 }),
        ShapePacking::pack(ShapeItem { color: '#ffaaff', material: 1, x: 8, y: 4, z: -2 }),
        ShapePacking::pack(ShapeItem { color: '#ffaaff', material: 1, x: 9, y: 4, z: -2 }),
        ShapePacking::pack(ShapeItem { color: '#ffaaff', material: 1, x: 10, y: 4, z: -2 }),
        ShapePacking::pack(ShapeItem { color: '#ffaaff', material: 1, x: 11, y: 4, z: -2 }),
        //
        ShapePacking::pack(ShapeItem { color: '#ffaaff', material: 1, x: 2, y: 4, z: -2 }),
        ShapePacking::pack(ShapeItem { color: '#ffaaff', material: 1, x: 3, y: 4, z: -2 }),
        ShapePacking::pack(ShapeItem { color: '#ffaaff', material: 1, x: 4, y: 4, z: -2 }),
        ShapePacking::pack(ShapeItem { color: '#ffaaff', material: 1, x: 5, y: 4, z: -2 }),
        ShapePacking::pack(ShapeItem { color: '#ffaaff', material: 1, x: 6, y: 4, z: -2 }),
        ShapePacking::pack(ShapeItem { color: '#ffaaff', material: 1, x: 7, y: 4, z: -2 }),
        ShapePacking::pack(ShapeItem { color: '#ffaaff', material: 1, x: 8, y: 4, z: -2 }),
        ShapePacking::pack(ShapeItem { color: '#ffaaff', material: 1, x: 9, y: 4, z: -2 }),
        ShapePacking::pack(ShapeItem { color: '#ffaaff', material: 1, x: 10, y: 4, z: -2 }),
        ShapePacking::pack(ShapeItem { color: '#ffaaff', material: 1, x: 11, y: 4, z: -2 }),
        //
        ShapePacking::pack(ShapeItem { color: '#ffaaff', material: 1, x: 2, y: 4, z: -2 }),
        ShapePacking::pack(ShapeItem { color: '#ffaaff', material: 1, x: 3, y: 4, z: -2 }),
        ShapePacking::pack(ShapeItem { color: '#ffaaff', material: 1, x: 4, y: 4, z: -2 }),
        ShapePacking::pack(ShapeItem { color: '#ffaaff', material: 1, x: 5, y: 4, z: -2 }),
        ShapePacking::pack(ShapeItem { color: '#ffaaff', material: 1, x: 6, y: 4, z: -2 }),
        ShapePacking::pack(ShapeItem { color: '#ffaaff', material: 1, x: 7, y: 4, z: -2 }),
        ShapePacking::pack(ShapeItem { color: '#ffaaff', material: 1, x: 8, y: 4, z: -2 }),
        ShapePacking::pack(ShapeItem { color: '#ffaaff', material: 1, x: 9, y: 4, z: -2 }),
        ShapePacking::pack(ShapeItem { color: '#ffaaff', material: 1, x: 10, y: 4, z: -2 }),
        ShapePacking::pack(ShapeItem { color: '#ffaaff', material: 1, x: 11, y: 4, z: -2 }),
        //
        ShapePacking::pack(ShapeItem { color: '#ffaaff', material: 1, x: 2, y: 4, z: -2 }),
        ShapePacking::pack(ShapeItem { color: '#ffaaff', material: 1, x: 3, y: 4, z: -2 }),
        ShapePacking::pack(ShapeItem { color: '#ffaaff', material: 1, x: 4, y: 4, z: -2 }),
        ShapePacking::pack(ShapeItem { color: '#ffaaff', material: 1, x: 5, y: 4, z: -2 }),
        ShapePacking::pack(ShapeItem { color: '#ffaaff', material: 1, x: 6, y: 4, z: -2 }),
        ShapePacking::pack(ShapeItem { color: '#ffaaff', material: 1, x: 7, y: 4, z: -2 }),
        ShapePacking::pack(ShapeItem { color: '#ffaaff', material: 1, x: 8, y: 4, z: -2 }),
        ShapePacking::pack(ShapeItem { color: '#ffaaff', material: 1, x: 9, y: 4, z: -2 }),
        ShapePacking::pack(ShapeItem { color: '#ffaaff', material: 1, x: 10, y: 4, z: -2 }),
        ShapePacking::pack(ShapeItem { color: '#ffaaff', material: 1, x: 11, y: 4, z: -2 }),
        //
        ShapePacking::pack(ShapeItem { color: '#ffaaff', material: 1, x: 2, y: 4, z: -2 }),
        ShapePacking::pack(ShapeItem { color: '#ffaaff', material: 1, x: 3, y: 4, z: -2 }),
        ShapePacking::pack(ShapeItem { color: '#ffaaff', material: 1, x: 4, y: 4, z: -2 }),
        ShapePacking::pack(ShapeItem { color: '#ffaaff', material: 1, x: 5, y: 4, z: -2 }),
        ShapePacking::pack(ShapeItem { color: '#ffaaff', material: 1, x: 6, y: 4, z: -2 }),
        ShapePacking::pack(ShapeItem { color: '#ffaaff', material: 1, x: 7, y: 4, z: -2 }),
        ShapePacking::pack(ShapeItem { color: '#ffaaff', material: 1, x: 8, y: 4, z: -2 }),
        ShapePacking::pack(ShapeItem { color: '#ffaaff', material: 1, x: 9, y: 4, z: -2 }),
        ShapePacking::pack(ShapeItem { color: '#ffaaff', material: 1, x: 10, y: 4, z: -2 }),
        ShapePacking::pack(ShapeItem { color: '#ffaaff', material: 1, x: 11, y: 4, z: -2 }),
        //
        ShapePacking::pack(ShapeItem { color: '#ffaaff', material: 1, x: 2, y: 4, z: -2 }),
        ShapePacking::pack(ShapeItem { color: '#ffaaff', material: 1, x: 3, y: 4, z: -2 }),
        ShapePacking::pack(ShapeItem { color: '#ffaaff', material: 1, x: 4, y: 4, z: -2 }),
        ShapePacking::pack(ShapeItem { color: '#ffaaff', material: 1, x: 5, y: 4, z: -2 }),
        ShapePacking::pack(ShapeItem { color: '#ffaaff', material: 1, x: 6, y: 4, z: -2 }),
        ShapePacking::pack(ShapeItem { color: '#ffaaff', material: 1, x: 7, y: 4, z: -2 }),
        ShapePacking::pack(ShapeItem { color: '#ffaaff', material: 1, x: 8, y: 4, z: -2 }),
        ShapePacking::pack(ShapeItem { color: '#ffaaff', material: 1, x: 9, y: 4, z: -2 }),
        ShapePacking::pack(ShapeItem { color: '#ffaaff', material: 1, x: 10, y: 4, z: -2 }),
        ShapePacking::pack(ShapeItem { color: '#ffaaff', material: 1, x: 11, y: 4, z: -2 }),
        //
        ShapePacking::pack(ShapeItem { color: '#ffaaff', material: 1, x: 2, y: 4, z: -2 }),
        ShapePacking::pack(ShapeItem { color: '#ffaaff', material: 1, x: 3, y: 4, z: -2 }),
        ShapePacking::pack(ShapeItem { color: '#ffaaff', material: 1, x: 4, y: 4, z: -2 }),
        ShapePacking::pack(ShapeItem { color: '#ffaaff', material: 1, x: 5, y: 4, z: -2 }),
        ShapePacking::pack(ShapeItem { color: '#ffaaff', material: 1, x: 6, y: 4, z: -2 }),
        ShapePacking::pack(ShapeItem { color: '#ffaaff', material: 1, x: 7, y: 4, z: -2 }),
        ShapePacking::pack(ShapeItem { color: '#ffaaff', material: 1, x: 8, y: 4, z: -2 }),
        ShapePacking::pack(ShapeItem { color: '#ffaaff', material: 1, x: 9, y: 4, z: -2 }),
        ShapePacking::pack(ShapeItem { color: '#ffaaff', material: 1, x: 10, y: 4, z: -2 }),
        ShapePacking::pack(ShapeItem { color: '#ffaaff', material: 1, x: 11, y: 4, z: -2 }),
        //
        ShapePacking::pack(ShapeItem { color: '#ffaaff', material: 1, x: 2, y: 4, z: -2 }),
        ShapePacking::pack(ShapeItem { color: '#ffaaff', material: 1, x: 3, y: 4, z: -2 }),
        ShapePacking::pack(ShapeItem { color: '#ffaaff', material: 1, x: 4, y: 4, z: -2 }),
        ShapePacking::pack(ShapeItem { color: '#ffaaff', material: 1, x: 5, y: 4, z: -2 }),
        ShapePacking::pack(ShapeItem { color: '#ffaaff', material: 1, x: 6, y: 4, z: -2 }),
        ShapePacking::pack(ShapeItem { color: '#ffaaff', material: 1, x: 7, y: 4, z: -2 }),
        ShapePacking::pack(ShapeItem { color: '#ffaaff', material: 1, x: 8, y: 4, z: -2 }),
        ShapePacking::pack(ShapeItem { color: '#ffaaff', material: 1, x: 9, y: 4, z: -2 }),
        ShapePacking::pack(ShapeItem { color: '#ffaaff', material: 1, x: 10, y: 4, z: -2 }),
        ShapePacking::pack(ShapeItem { color: '#ffaaff', material: 1, x: 11, y: 4, z: -2 }),
        //
        ShapePacking::pack(ShapeItem { color: '#ffaaff', material: 1, x: 2, y: 4, z: -2 }),
        ShapePacking::pack(ShapeItem { color: '#ffaaff', material: 1, x: 3, y: 4, z: -2 }),
        ShapePacking::pack(ShapeItem { color: '#ffaaff', material: 1, x: 4, y: 4, z: -2 }),
        ShapePacking::pack(ShapeItem { color: '#ffaaff', material: 1, x: 5, y: 4, z: -2 }),
        ShapePacking::pack(ShapeItem { color: '#ffaaff', material: 1, x: 6, y: 4, z: -2 }),
        ShapePacking::pack(ShapeItem { color: '#ffaaff', material: 1, x: 7, y: 4, z: -2 }),
        ShapePacking::pack(ShapeItem { color: '#ffaaff', material: 1, x: 8, y: 4, z: -2 }),
        ShapePacking::pack(ShapeItem { color: '#ffaaff', material: 1, x: 9, y: 4, z: -2 }),
        ShapePacking::pack(ShapeItem { color: '#ffaaff', material: 1, x: 10, y: 4, z: -2 }),
        ShapePacking::pack(ShapeItem { color: '#ffaaff', material: 1, x: 11, y: 4, z: -2 }),
    ]
        .span()
}

