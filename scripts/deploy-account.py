from starkware.crypto.signature.signature import (
    pedersen_hash, private_to_stark_key, sign
)
private_key = 12345
public_key = private_to_stark_key(private_key)
print(f'Private Key: {private_key}, Public key: {public_key}')

import subprocess

if (False):
    deployment = subprocess.run(["starknet", "deploy", "--contract", "../cairo-contracts/account.json",
        "--inputs", str(public_key),
        "--network", "alpha"], capture_output=True, encoding="utf8")

    print(f"Out: {deployment.stdout}")
    print(f"Err: {deployment.stderr}")
else:
    addr = "0x029aaa6c4abb3d009a138aad90cceb51ab2c18ac76c2e874d019caf6eafdc485"
    deployment = subprocess.run(["starknet", "invoke", "--function", "initialize",
        "--abi", "../cairo-contracts/account_abi.json",
        "--inputs", str(addr),
        "--address", str(addr),
        "--network", "alpha"], capture_output=True, encoding="utf8")

    print(f"Out: {deployment.stdout}")
    print(f"Err: {deployment.stderr}")
