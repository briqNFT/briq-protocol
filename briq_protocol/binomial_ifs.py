from briq_protocol.gen_shape_check import ShapeItem, generate_shape_check

HEADER = """
// This contract is only declared, and call via LibraryDispatcher & class_hash
#[starknet::contract]
mod shapes_verifier {
    use array::{SpanTrait, ArrayTrait};
    use option::OptionTrait;

    // Copied from briq_protocol to keep this simple.
    #[derive(Copy, Drop, Serde,)]
    struct FTSpec {
        token_id: felt252,
        qty: u128,
    }

    #[derive(Copy, Drop, Serde, Store)]
    struct PackedShapeItem {
        color_material: felt252,
        x_y_z: felt252,
    }

    #[storage]
    struct Storage {}

    """


def generate_binary_search_function(nft_ids, check_generator):
    """
    :param nft_ids: List of NFT IDs, sorted.
    :param data_checks: List of code snippets for each NFT. Must be the same length as nft_ids.
    :return: Contract function string.
    """
    def recursive_search(low, high):
        if low > high:
            return ""  # or some other default action

        mid = (low + high) // 2

        if low == high:
            return f"if attribute_id == {nft_ids[mid]} {{\n    {check_generator(nft_ids[mid])}\n    return;\n}}"

        return f"""
        if attribute_id == {nft_ids[mid]} {{
            {check_generator(mid)}
        }} else if attribute_id < {nft_ids[mid]} {{
            {recursive_search(low, mid - 1)}
        }} else {{
            {recursive_search(mid + 1, high)}
        }}
        """

    return f"""
    #[external(v0)]
    fn verify_shape(
        self: @ContractState, attribute_id: u64, mut shape: Span<PackedShapeItem>, mut fts: Span<FTSpec>
    ) {{
        {recursive_search(0, len(nft_ids) - 1)}
        assert(false, 'bad attribute ID');
    }}
    """


def shape_check(index):
    return generate_shape_check([
        ShapeItem(0, 0, 0, "#ffaaff", 1),
        ShapeItem(0, 1, 0, "#ffaaff", 1),
    ])

#  print(HEADER + generate_binary_search_function([1, 2, 3, 10, 200], shape_check) + "\n}")
