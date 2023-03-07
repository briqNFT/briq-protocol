auction_data = {
    1: {
        "box_token_id": 0xcafe,
        "quantity": 10,
        "auction_start": 198,
        "auction_duration": 24 * 60 * 60,
        "initial_price": 2,
    },
    2: {
        "box_token_id": 0xfade,
        "quantity": 20,
        "auction_start": 198,
        "auction_duration": 24 * 60 * 60,
        "initial_price": 2,
    }
}

box_address = 0xcafe
erc20_address = 0xfade

def generate_auction(box_address=box_address, erc20_address=box_address, auction_data=auction_data):
    lines = []

    lines.append(f"const box_address = {box_address};")
    lines.append(f"const erc20_address = {erc20_address};")

    lines.append("auction_data_start:")
    i = 1
    for key in auction_data:
        if key != i:
            print("Bad auction_data")
            raise
        lines.append(f'dw {auction_data[key]["box_token_id"]};')
        lines.append(f'dw {auction_data[key]["quantity"]};')
        lines.append(f'dw {auction_data[key]["auction_start"]};')
        lines.append(f'dw {auction_data[key]["auction_duration"]};')
        lines.append(f'dw {auction_data[key]["initial_price"]};')
        i += 1
    lines.append("auction_data_end:")

    return '%lang starknet\n' + '\n'.join(lines) + '\n'
