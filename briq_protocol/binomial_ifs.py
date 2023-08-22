from briq_protocol.gen_shape_check import ShapeItem, generate_shape_check

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
            return f"if nft_id == {nft_ids[mid]} {{\n    {check_generator(mid)}\n}}"

        return f"""
        if nft_id == {nft_ids[mid]} {{
            {check_generator(mid)}
        }} else if nft_id < {nft_ids[mid]} {{
            {recursive_search(low, mid - 1)}
            return true;
        }} else {{
            {recursive_search(mid + 1, high)}
            return true;
        }}
        """

    return f"""
    pub fn check_nft(nft_id: u32) {{
        {recursive_search(0, len(nft_ids) - 1)}
        assert(false, 'bad token ID');
        return false;
    }}
    """

def shape_check(index):
    return generate_shape_check([
        ShapeItem(0, 0, 0, "#ffaaff", 1),
        ShapeItem(0, 1, 0, "#ffaaff", 1),
    ])

print(generate_binary_search_function([1, 2, 3, 10, 200], shape_check))
