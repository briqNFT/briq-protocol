import os

from nile.nre import NileRuntimeEnvironment


def run(nre: NileRuntimeEnvironment):
    if not os.getenv("ADMIN"):
        print("ADMIN env variable must be set to the address of the admin wallet")

    #os.environ["toto"] = "123456"
    #account = nre.get_or_deploy_account("toto")
    #print(f"Deployed deploy account to {account.address}")

    briq_interface_addr, abi = nre.deploy("briq_interface", arguments=[], alias="briq_interface")
    set_interface_addr, abi = nre.deploy("set_interface", arguments=[], alias="set_interface")

    briq_address, abi = nre.deploy("proxy", arguments=[os.getenv("ADMIN"), briq_interface_addr], alias="briq_proxy")
    set_address, abi = nre.deploy("proxy", arguments=[os.getenv("ADMIN"), set_interface_addr], alias="set_proxy")

    print(f"Deployed briq to {briq_address}")
    print(f"Deployed set to {set_address}")

    #account.send(briq_address, "setSetAddress_", [int(set_address, 16)])
    #account.send(set_address, "setBriqAddress_", [int(briq_address, 16)])
