import subprocess
import re

contract = subprocess.run(["starknet", "deploy", "--contract", "briq.json", "--network", "alpha"], capture_output=True, encoding="utf-8")
briq_address = re.search("Contract address: ([0-9a-z]+)", contract.stdout).group(1)
print(f'export ADDRESS="{briq_address}"')

contract = subprocess.run(["starknet", "deploy", "--contract", "mint_proxy.json", "--network", "alpha", "--inputs", briq_address], capture_output=True, encoding="utf-8")
mint_address = re.search("Contract address: ([0-9a-z]+)", contract.stdout).group(1)
print(f'export MINT_ADDRESS="{mint_address}"')

contract = subprocess.run(["starknet", "deploy", "--contract", "set.json", "--network", "alpha"], capture_output=True, encoding="utf-8")
set_address = re.search("Contract address: ([0-9a-z]+)", contract.stdout).group(1)
print(f'export SET_ADDRESS="{set_address}"')
print('export GATEWAY_URL="http://localhost:4999/"')

