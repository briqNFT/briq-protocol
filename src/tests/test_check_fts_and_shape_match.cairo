use briq_protocol::set_nft::assembly::check_fts_and_shape_match;
use briq_protocol::types::{FTSpec, ShapeItem, PackedShapeItem, ShapePacking};

#[test]
#[available_gas(3000000000)]
fn test_ok_1() {
    let fts = array![
        FTSpec { qty: 2, token_id: 0x1 },
    ];
    let shape = array![
        ShapePacking::pack(ShapeItem { color: '#ffaaff', material: 0x1, x: 2, y: 4, z: -2 }),
        ShapePacking::pack(ShapeItem { color: '#ffaaff', material: 0x1, x: 2, y: 5, z: -2 }),
    ];
    check_fts_and_shape_match(fts.span(), shape.span());
}

#[test]
#[available_gas(3000000000)]
fn test_ok_2() {
    let fts = array![
        FTSpec { qty: 4, token_id: 0x1 },
        FTSpec { qty: 2, token_id: 0x2 },
        FTSpec { qty: 1, token_id: 0x4 },
    ];
    let shape = array![
        ShapePacking::pack(ShapeItem { color: '#ffaaff', material: 0x1, x: 2, y: 1, z: 0 }),
        ShapePacking::pack(ShapeItem { color: '#ffaaff', material: 0x1, x: 2, y: 2, z: 0 }),
        ShapePacking::pack(ShapeItem { color: '#ffaaff', material: 0x2, x: 2, y: 2, z: 4 }),
        ShapePacking::pack(ShapeItem { color: '#ffaaff', material: 0x1, x: 3, y: 0, z: 0 }),
        ShapePacking::pack(ShapeItem { color: '#ffaaff', material: 0x2, x: 4, y: -2, z: -100 }),
        ShapePacking::pack(ShapeItem { color: '#ffaaff', material: 0x4, x: 4, y: -1, z: -100 }),
        ShapePacking::pack(ShapeItem { color: '#ffaaff', material: 0x1, x: 5, y: -3, z: -100 }),
    ];
    check_fts_and_shape_match(fts.span(), shape.span());
}

#[test]
#[available_gas(3000000000)]
#[should_panic(expected: ('Bad FTS', ))]
fn test_bad_fts_1() {
    let fts = array![
        FTSpec { qty: 2, token_id: 0x1 },
    ];
    let shape = array![
        ShapePacking::pack(ShapeItem { color: '#ffaaff', material: 0x1, x: 2, y: 1, z: 0 }),
    ];
    check_fts_and_shape_match(fts.span(), shape.span());
}


#[test]
#[available_gas(3000000000)]
#[should_panic(expected: ('Bad FTS', ))]
fn test_bad_fts_2() {
    let fts = array![
        FTSpec { qty: 2, token_id: 0x1 },
    ];
    let shape = array![
    ];
    check_fts_and_shape_match(fts.span(), shape.span());
}


#[test]
#[available_gas(3000000000)]
#[should_panic(expected: ('Bad FTS', ))]
fn test_bad_fts_3() {
    let fts = array![
    ];
    let shape = array![
        ShapePacking::pack(ShapeItem { color: '#ffaaff', material: 0x1, x: 2, y: 1, z: 0 }),
    ];
    check_fts_and_shape_match(fts.span(), shape.span());
}


#[test]
#[available_gas(3000000000)]
#[should_panic(expected: ('Bad FTS', ))]
fn test_bad_fts_4() {
    let fts = array![
        FTSpec { qty: 1, token_id: 0x1 },
        FTSpec { qty: 1, token_id: 0x2 },
    ];
    let shape = array![
        ShapePacking::pack(ShapeItem { color: '#ffaaff', material: 0x1, x: 0, y: 0, z: 0 }),
    ];
    check_fts_and_shape_match(fts.span(), shape.span());
}

#[test]
#[available_gas(3000000000)]
#[should_panic(expected: ('Bad FTS', ))]
fn test_bad_fts_5() {
    let fts = array![
        FTSpec { qty: 1, token_id: 0x1 },
        FTSpec { qty: 1, token_id: 0x2 },
    ];
    let shape = array![
        ShapePacking::pack(ShapeItem { color: '#ffaaff', material: 0x1, x: 0, y: 0, z: 0 }),
        ShapePacking::pack(ShapeItem { color: '#ffaaff', material: 0x2, x: 1, y: 0, z: 0 }),
        ShapePacking::pack(ShapeItem { color: '#ffaaff', material: 0x3, x: 2, y: 0, z: 0 }),
    ];
    check_fts_and_shape_match(fts.span(), shape.span());
}

#[test]
#[available_gas(3000000000)]
#[should_panic(expected: ('Bad ordering', ))]
fn test_shape_ordering_bad_duplicate() {
    let shape = array![
        ShapePacking::pack(ShapeItem { color: '#ffaaff', material: 0x1, x: 0, y: 0, z: 0 }),
        ShapePacking::pack(ShapeItem { color: '#ffaaff', material: 0x1, x: 0, y: 0, z: 0 }),
    ];
    check_fts_and_shape_match(array![].span(), shape.span());
}

#[test]
#[available_gas(3000000000)]
#[should_panic(expected: ('Bad ordering', ))]
fn test_shape_ordering_bad_ordering_1() {
    let shape = array![
        ShapePacking::pack(ShapeItem { color: '#ffaaff', material: 0x1, x: 0, y: 0, z: 0 }),
        ShapePacking::pack(ShapeItem { color: '#ffaaff', material: 0x1, x: 0, y: 0, z: -1 }),
    ];
    check_fts_and_shape_match(array![].span(), shape.span());
}

#[test]
#[available_gas(3000000000)]
#[should_panic(expected: ('Bad ordering', ))]
fn test_shape_ordering_bad_ordering_2() {
    let shape = array![
        ShapePacking::pack(ShapeItem { color: '#ffaaff', material: 0x1, x: 0, y: 0, z: 0 }),
        ShapePacking::pack(ShapeItem { color: '#ffaaff', material: 0x1, x: 0, y: -1, z: 0 }),
    ];
    check_fts_and_shape_match(array![].span(), shape.span());
}

#[test]
#[available_gas(3000000000)]
#[should_panic(expected: ('Bad ordering', ))]
fn test_shape_ordering_bad_ordering_3() {
    let shape = array![
        ShapePacking::pack(ShapeItem { color: '#ffaaff', material: 0x1, x: 0, y: 0, z: 0 }),
        ShapePacking::pack(ShapeItem { color: '#ffaaff', material: 0x1, x: -1, y: 0, z: 0 }),
    ];
    check_fts_and_shape_match(array![].span(), shape.span());
}


#[test]
#[available_gas(3000000000)]
#[should_panic(expected: ('Bad ordering', ))]
fn test_shape_ordering_bad_ordering_4() {
    let shape = array![
        ShapePacking::pack(ShapeItem { color: '#ffaaff', material: 0x1, x: 0, y: 0, z: 0 }),
        ShapePacking::pack(ShapeItem { color: '#ffaaff', material: 0x1, x: -1, y: -1, z: -1 }),
    ];
    check_fts_and_shape_match(array![].span(), shape.span());
}

#[test]
#[available_gas(3000000000)]
#[should_panic(expected: ('Bad ordering', ))]
fn test_shape_ordering_bad_ordering_5() {
    let shape = array![
        ShapePacking::pack(ShapeItem { color: '#ffaaff', material: 0x1, x: 1, y: 0, z: 0 }),
        ShapePacking::pack(ShapeItem { color: '#ffaaff', material: 0x1, x: 0, y: 0, z: 0 }),
    ];
    check_fts_and_shape_match(array![].span(), shape.span());
}

#[test]
#[available_gas(3000000000)]
#[should_panic(expected: ('Bad ordering', ))]
fn test_shape_ordering_bad_ordering_6() {
    let shape = array![
        ShapePacking::pack(ShapeItem { color: '#ffaaff', material: 0x1, x: 0, y: 1, z: 0 }),
        ShapePacking::pack(ShapeItem { color: '#ffaaff', material: 0x1, x: 0, y: 0, z: 0 }),
    ];
    check_fts_and_shape_match(array![].span(), shape.span());
}

#[test]
#[available_gas(3000000000)]
#[should_panic(expected: ('Bad ordering', ))]
fn test_shape_ordering_bad_ordering_7() {
    let shape = array![
        ShapePacking::pack(ShapeItem { color: '#ffaaff', material: 0x1, x: 0, y: 0, z: 1 }),
        ShapePacking::pack(ShapeItem { color: '#ffaaff', material: 0x1, x: 0, y: 0, z: 0 }),
    ];
    check_fts_and_shape_match(array![].span(), shape.span());
}
