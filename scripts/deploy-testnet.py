import subprocess

devnet = subprocess.Popen(["starknet-devnet", "--port", "4999"], stdout=subprocess.PIPE, stderr=subprocess.PIPE, encoding="utf-8")

import time

i = 0
while True:
    err = devnet.stderr.readline()
    time.sleep(1)
    i = i + 1
    if i > 5:
        raise Exception('could not start devnet')
    if "Running" in err:
        break

import re

print("Devnet is running, proceeding to deploy")
contract = subprocess.run(["starknet", "deploy", "--contract", "briq.json", "--gateway_url", "http://localhost:4999"], capture_output=True, encoding="utf-8")
briq_address = re.search("Contract address: ([0-9a-z]+)", contract.stdout).group(1)
print(f'export ADDRESS="{briq_address}"')

contract = subprocess.run(["starknet", "deploy", "--contract", "set.json", "--gateway_url", "http://localhost:4999"], capture_output=True, encoding="utf-8")
set_address = re.search("Contract address: ([0-9a-z]+)", contract.stdout).group(1)
print(f'export SET_ADDRESS="{set_address}"')
print('export GATEWAY_URL="http://localhost:4999/"')

# Call init on set
subprocess.run(["starknet", "invoke",
    "--function", "initialize", "--abi", "briq_abi.json", "--address", briq_address, "--inputs", set_address,
    "--gateway_url", "http://localhost:4999"])
subprocess.run(["starknet", "invoke",
    "--function", "initialize", "--abi", "set_abi.json", "--address", set_address, "--inputs", briq_address,
    "--gateway_url", "http://localhost:4999"])



import select
    
y = select.poll()
y.register(devnet.stdout, select.POLLIN)
z = select.poll()
z.register(devnet.stderr, select.POLLIN)

while True:
  if y.poll(1):
     print(devnet.stdout.readline())
  elif z.poll(1):
     print(devnet.stderr.readline())
  else:
     time.sleep(1)
