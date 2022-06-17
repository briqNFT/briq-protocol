auction_data = {
    1: {
        "box_token_id": 0xcafe,
        "quantity": 10,
        "auction_start": 198,
        "auction_duration": 24 * 60 * 60,
    },
    2: {
        "box_token_id": 0xfade,
        "quantity": 20,
        "auction_start": 198,
        "auction_duration": 24 * 60 * 60,
    }
}

box_address = 0xcafe

def generate_auction(auction_data=auction_data, box_address=box_address):
    lines = []

    lines.append(f"const box_address = {box_address}")

    lines.append("auction_data_start:")
    i = 1
    for key in auction_data:
        if key != i:
            print("Bad auction_data")
            raise
        lines.append(f'dw {auction_data[key]["box_token_id"]}')
        lines.append(f'dw {auction_data[key]["quantity"]}')
        lines.append(f'dw {auction_data[key]["auction_start"]}')
        lines.append(f'dw {auction_data[key]["auction_duration"]}')
        i += 1
    lines.append("auction_data_end:")

    return '%lang starknet\n' + '\n'.join(lines) + '\n'
