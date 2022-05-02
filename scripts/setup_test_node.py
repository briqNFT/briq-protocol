from nile.nre import NileRuntimeEnvironment
from nile import signer

import os


# NB: for now, run the starknet devnet node manually.

def run(nre: NileRuntimeEnvironment):
    if nre.network != "127.0.0.1":
        print("Error: should run on 127.0.0.1")
    try:
        os.unlink("127.0.0.1.deployments.txt")
    except:
        pass

    try:
        os.unlink("127.0.0.1.accounts.json")
    except:
        pass

    # For some reason this references an env variable.
    os.environ["toto"] = "123456"
    account = nre.get_or_deploy_account("toto")
    print(f"Deployed account to {account.address}")

    briq_impl_addr, abi = nre.deploy("briq_impl", arguments=[], alias="briq_impl")
    set_impl_addr, abi = nre.deploy("set_impl", arguments=[], alias="set_impl")

    briq_address, abi = nre.deploy("_proxy", arguments=[account.address, briq_impl_addr], alias="briq_proxy")
    set_address, abi = nre.deploy("_proxy", arguments=[account.address, set_impl_addr], alias="set_proxy")

    print(f"Deployed briq to {briq_address}")
    print(f"Deployed set to {set_address}")

    account.send(briq_address, "setSetAddress", [int(set_address, 16)])
    account.send(set_address, "setBriqAddress", [int(briq_address, 16)])

    mint_address, abi = nre.deploy("mint", arguments=[briq_address, "1000"], alias="mint")
    account.send(briq_address, "setMintContract", [int(mint_address, 16)])
    account.send(briq_address, "setAdmin", [int("0x030fe8f19ab0436a74a7498baa8003eb47aea7e543807df0f8f0c7783f7e7400", 16)])
    account.send(set_address, "setAdmin", [int("0x030fe8f19ab0436a74a7498baa8003eb47aea7e543807df0f8f0c7783f7e7400", 16)])
