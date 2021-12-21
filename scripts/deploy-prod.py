import subprocess
import re
import os

NETWORK = os.environ.get('NET') or 'alpha-goerli'
TOKEN = os.environ.get('TOKEN')

TOKEN_ARGS = ['--token', TOKEN] if TOKEN else []

contract = subprocess.run(["starknet", "deploy", "--contract", "briq.json", "--network", NETWORK] + TOKEN_ARGS, capture_output=True, encoding="utf-8")
briq_address = re.search("Contract address: ([0-9a-z]+)", contract.stdout).group(1)
print(f'export ADDRESS="{briq_address}"')

contract = subprocess.run(["starknet", "deploy", "--contract", "mint_proxy.json", "--network", NETWORK, "--inputs", briq_address] + TOKEN_ARGS, capture_output=True, encoding="utf-8")
mint_address = re.search("Contract address: ([0-9a-z]+)", contract.stdout).group(1)
print(f'export MINT_ADDRESS="{mint_address}"')

contract = subprocess.run(["starknet", "deploy", "--contract", "set.json", "--network", NETWORK] + TOKEN_ARGS, capture_output=True, encoding="utf-8")
set_address = re.search("Contract address: ([0-9a-z]+)", contract.stdout).group(1)
print(f'export SET_ADDRESS="{set_address}"')
