import argparse

parser = argparse.ArgumentParser(description='Generate a proxy contract.')
parser.add_argument('target', help='The name of the target contract')
args = parser.parse_args()

if args.target == "set":
    from .backend_set import generate
    print(generate())
elif args.target == "briq":
    from .backend_briq import generate
    print(generate())
