use briq_protocol::types::{ShapeItem, PackedShapeItem, ShapePacking};

use debug::PrintTrait;

#[test]
#[available_gas(3000000000)]
fn test_shape_packing_a() {
    let shape = ShapeItem {
        color: '#ffaaff'.try_into().unwrap(),
        material: 1,
        x: 1,
        y: 2,
        z: 3,
    };
    let packed = ShapePacking::pack(shape);
    packed.color_material.print();
    packed.x_y_z.print();
    assert(packed.color_material == 0x236666616166660000000000000001, 'bad color mat packing');
    assert(packed.x_y_z == 0x800000018000000280000003, 'bad color mat packing');
    let unpacked = ShapePacking::unpack(packed);
    assert(unpacked.color == '#ffaaff'.try_into().unwrap(), 'bad color unpacking');
    assert(unpacked.material == 1, 'bad material unpacking');
    assert(unpacked.x == shape.x, 'bad x unpacking');
    assert(unpacked.y == shape.y, 'bad y unpacking');
    assert(unpacked.z == shape.z, 'bad z unpacking');
}

#[test]
#[available_gas(3000000000)]
fn test_shape_packing_b() {
    let shape = ShapeItem {
        color: '#ffaaff'.try_into().unwrap(),
        material: 1,
        x: 0,
        y: 0,
        z: 0,
    };
    let packed = ShapePacking::pack(shape);
    packed.color_material.print();
    packed.x_y_z.print();
    assert(packed.color_material == 0x236666616166660000000000000001, 'bad color mat packing');
    assert(packed.x_y_z == 0x800000008000000080000000, 'bad color mat packing');
    let unpacked = ShapePacking::unpack(packed);
    assert(unpacked.color == '#ffaaff'.try_into().unwrap(), 'bad color unpacking');
    assert(unpacked.material == 1, 'bad material unpacking');
    assert(unpacked.x == shape.x, 'bad x unpacking');
    assert(unpacked.y == shape.y, 'bad y unpacking');
    assert(unpacked.z == shape.z, 'bad z unpacking');}



#[test]
#[available_gas(3000000000)]
fn test_shape_packing_c() {
    let shape = ShapeItem {
        color: '#ffaaff'.try_into().unwrap(),
        material: 1,
        x: -1,
        y: -0x80000000,
        z: -1,
    };
    let packed = ShapePacking::pack(shape);
    assert(packed.color_material == 0x236666616166660000000000000001, 'bad color mat packing');
    assert(packed.x_y_z == 0x7fffffff000000007fffffff, 'bad color mat packing');
    let unpacked = ShapePacking::unpack(packed);
    assert(unpacked.color == '#ffaaff'.try_into().unwrap(), 'bad color unpacking');
    assert(unpacked.material == 1, 'bad material unpacking');
    assert(unpacked.x == shape.x, 'bad x unpacking');
    assert(unpacked.y == shape.y, 'bad y unpacking');
    assert(unpacked.z == shape.z, 'bad z unpacking');}
