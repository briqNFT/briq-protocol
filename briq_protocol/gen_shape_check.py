
def generate_shape_check(shape):
    materials = {}
    for shapeItem in shape:
        if shapeItem.color_nft_material not in materials:
            materials[shapeItem.color_nft_material] = 0
        materials[shapeItem.color_nft_material] += 1
    return f"""
fn check_shape_numbers(
    mut shape: Span<ShapeItem>,
    mut fts: Span<FTSpec>,
) {{
    assert(shape.len() == {len(shape)}, 'bad shape length');
    assert(fts.len() == {len(materials)}, 'bad ft spec');
    assert(fts.at(0).unwrap().ft == 0, 'bad ft spec');
    assert(fts.at(1).unwrap().ft == 1, 'bad ft spec');
    assert(fts.at(0).unwrap().quant == {materials[0]}, 'bad ft spec');
    assert(fts.at(1).unwrap().quant == {materials[1]}, 'bad ft spec');

""" + '\n'.join([item_check(item) for item in shape]) + """
}}
"""

ANY_MATERIAL_ANY_COLOR = 0

def item_check(item):
    out = [
        "    let shapeItem = shape.pop_front().unwrap()",
    ]
    if item.color_nft_material != ANY_MATERIAL_ANY_COLOR:
        out.append(f"assert(shapeItem.color_nft_material == {item.color_nft_material}, 'bad shape item')")
    out.append(f"assert(shapeItem.x_y_z == {item.x_y_z}, 'bad shape item')")
    return "\n    ".join(out)

class ShapeItem:
    def __init__(self, x_y_z, color_nft_material, material):
        self.x_y_z = x_y_z
        self.color_nft_material = color_nft_material
        self.material = material

print(generate_shape_check([
    ShapeItem(0, 0, 0),
    ShapeItem(1, 0, 0),
    ShapeItem(2, 1, 1),
]))