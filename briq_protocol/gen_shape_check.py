
from dataclasses import dataclass
from typing import Dict

ANY_MATERIAL_ANY_COLOR = 0

def generate_shape_check(shape):
    materials = {}
    for shapeItem in shape:
        if shapeItem.material == ANY_MATERIAL_ANY_COLOR:
            continue
        if shapeItem.material not in materials:
            materials[shapeItem.material] = 0
        materials[shapeItem.material] += 1
    return f"""
    assert(shape.len() == {len(shape)}, 'bad shape length');
    let mut ftsum = 0;
    loop {{
        if fts.len() == 0 {{
            break;
        }}
        ftsum = ftsum + *(fts.pop_front().unwrap().qty);
    }};
    assert(ftsum == shape.len().into(), 'bad fts spec');
""" + '\n'.join([item_check(item) for item in shape])


def item_check(item):
    out = [
        "    let shapeItem = shape.pop_front().unwrap();",
    ]
    if item.material != ANY_MATERIAL_ANY_COLOR:
        out.append(f"assert(shapeItem.color_material == @{item.color_material}, 'bad shape item');")
    out.append(f"assert(shapeItem.x_y_z == @{item.x_y_z}, 'bad shape item');")
    return "\n    ".join(out)


@dataclass
class ShapeItem:
    x: int
    y: int
    z: int
    color: str
    material: int

    @property
    def color_material(self):
        return int.from_bytes(self.color.encode(), 'big') * 2**64 + self.material

    @property
    def x_y_z(self):
        return (self.x + 2**31) * 2**64 + (self.y + 2**31) * 2**32 + (self.z + 2**31)
