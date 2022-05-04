import argparse
from .generate_interface import generate

parser = argparse.ArgumentParser(description='Generate an interface contract.')
parser.add_argument('source', help='The name of the source contract.')
args = parser.parse_args()

generate(args.source, f"contracts/{args.source}_interface.cairo")
