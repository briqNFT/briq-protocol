import subprocess
import re
import os

NETWORK = os.environ.get('NET') or 'alpha-goerli'
TOKEN = os.environ.get('TOKEN')

BRIQ = os.environ.get('BRIQ_ADDRESS')
SET = os.environ.get('SET_ADDRESS')
MINT = os.environ.get('MINT_ADDRESS')
ERC20 = os.environ.get('ERC20_ADDRESS')

TOKEN_ARGS = ['--token', TOKEN] if TOKEN else []

subprocess.run(["scripts/compile.sh"])

if not BRIQ:
    contract = subprocess.run(["starknet", "deploy", "--contract", "briq.json", "--network", NETWORK] + TOKEN_ARGS, capture_output=True, encoding="utf-8")
    BRIQ = re.search("Contract address: ([0-9a-z]+)", contract.stdout).group(1)
    print(contract.stdout)

if not MINT:
    contract = subprocess.run(["starknet", "deploy", "--contract", "mint_proxy.json", "--network", NETWORK, "--inputs", BRIQ, "100"] + TOKEN_ARGS, capture_output=True, encoding="utf-8")
    MINT = re.search("Contract address: ([0-9a-z]+)", contract.stdout).group(1)
    print(contract.stdout)

if not SET:
    contract = subprocess.run(["starknet", "deploy", "--contract", "set.json", "--network", NETWORK] + TOKEN_ARGS, capture_output=True, encoding="utf-8")
    SET = re.search("Contract address: ([0-9a-z]+)", contract.stdout).group(1)
    print(contract.stdout)

if not ERC20:
    import codecs
    token_name = '0x' + codecs.encode(b"briq", "hex").decode("ascii")
    contract = subprocess.run(["starknet", "deploy", "--contract", "briq_erc20.json", "--network", NETWORK,
        "--inputs", token_name, token_name, BRIQ] + TOKEN_ARGS, capture_output=True, encoding="utf-8")
    ERC20 = re.search("Contract address: ([0-9a-z]+)", contract.stdout).group(1)
    print(contract.stdout)

print(f'export BRIQ_ADDRESS="{BRIQ}"')
print(f'export MINT_ADDRESS="{MINT}"')
print(f'export SET_ADDRESS="{SET}"')
print(f'export ERC20_ADDRESS="{ERC20}"')
