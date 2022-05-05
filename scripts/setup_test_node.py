from nile.nre import NileRuntimeEnvironment

import os


# NB: for now, run the starknet devnet node manually.

def run(nre: NileRuntimeEnvironment):
    if nre.network != "127.0.0.1":
        print("Error: should run on 127.0.0.1")
        exit(1)
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

    briq_interface_addr, abi = nre.deploy("briq_interface", arguments=[], alias="briq_interface")
    set_interface_addr, abi = nre.deploy("set_interface", arguments=[], alias="set_interface")

    briq_address, abi = nre.deploy("proxy", arguments=[account.address, briq_interface_addr], alias="briq_proxy")
    set_address, abi = nre.deploy("proxy", arguments=[account.address, set_interface_addr], alias="set_proxy")

    print(f"Deployed briq to {briq_address}")
    print(f"Deployed set to {set_address}")

    account.send(briq_address, "setSetAddress_", [int(set_address, 16)])
    account.send(set_address, "setBriqAddress_", [int(briq_address, 16)])

    #mint_address, abi = nre.deploy("mint", arguments=[briq_address, "1000"], alias="mint")
    #account.send(briq_address, "setMintContract", [int(mint_address, 16)])
    #account.send(briq_address, "setAdmin", [int("0x030fe8f19ab0436a74a7498baa8003eb47aea7e543807df0f8f0c7783f7e7400", 16)])
    #account.send(set_address, "setAdmin", [int("0x030fe8f19ab0436a74a7498baa8003eb47aea7e543807df0f8f0c7783f7e7400", 16)])
