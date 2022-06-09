import argparse
from .generate_box import generate_box
from .generate_interface import generate

parser = argparse.ArgumentParser(description='Generate contracts.')
parser.add_argument('--box', help='Generate the box contract', action="store_true")
parser.add_argument('--source', help='The name of the source contract.')
args = parser.parse_args()

if args.box:
    with open('contracts/box_erc1155/data.cairo', 'w') as f:
        f.write(generate_box())
else:
    generate(args.source, f"contracts/{args.source}_interface.cairo")
