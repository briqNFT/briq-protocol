
from dataclasses import dataclass
from typing import Dict


def generate_shape_check(shape):
    materials = {}
    for shapeItem in shape:
        if shapeItem.material not in materials:
            materials[shapeItem.material] = 0
        materials[shapeItem.material] += 1
    return f"""
    assert(shape.len() == {len(shape)}, 'bad shape length');
    assert(fts.len() == {len(materials)}, 'bad ft spec');
    {mat_check(materials)}
""" + '\n'.join([item_check(item) for item in shape])

def mat_check(materials: Dict[int, int]):
    out = []
    i = 0
    for material, count in materials.items():
        out.append(f"assert(fts.at({i}).token_id == @{material}, 'bad ft spec');")
        out.append(f"assert(fts.at({i}).qty == @{count}, 'bad ft spec');")
        i += 1
    return "\n    ".join(out)

ANY_MATERIAL = 0
ANY_COLOR = 0

def item_check(item):
    out = [
        "    let shapeItem = shape.pop_front().unwrap();",
    ]
    if item.material != ANY_COLOR:
        out.append(f"assert(shapeItem.color == '{item.color}', 'bad shape item');")
    if item.material != ANY_MATERIAL:
        out.append(f"assert(shapeItem.material == {item.material}, 'bad shape item');")
    out.append(f"assert(shapeItem.x == {item.x}, 'bad shape item');")
    out.append(f"assert(shapeItem.z == {item.y}, 'bad shape item');")
    out.append(f"assert(shapeItem.y == {item.z}, 'bad shape item');")
    return "\n    ".join(out)

@dataclass
class ShapeItem:
    x: int
    y: int
    z: int
    color: str
    material: int
