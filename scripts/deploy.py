from nile.core.account import account_raw_execute, account_send, account_setup

import os

os.environ["SIGNER"] = "123456"

def run(nre):
    signer = account_setup("SIGNER", nre.network)
    print(f"Signer account: {signer.account}")

    briq_impl, abi = nre.deploy("briq_backend", arguments=[], alias="briq_backend_impl")
    set_impl, abi = nre.deploy("set_backend", arguments=[], alias="set_backend_impl")

    briq_address, abi = nre.deploy("_proxy", arguments=[signer.account, briq_impl], alias="briq_backend")
    set_address, abi = nre.deploy("_proxy", arguments=[signer.account, set_impl], alias="set_backend")

    print(f"Deployed briq to {briq_address}")
    print(f"Deployed set to {set_address}")

    account_send("SIGNER", "briq_backend", "setSetBackendAddress", params=[set_address], network=nre.network)
    account_send("SIGNER", "set_backend", "setBriqBackendAddress", params=[briq_address], network=nre.network)

    mint_address, abi = nre.deploy("mint", arguments=[briq_address, "1000"], alias="mint")
    account_send("SIGNER", "briq_backend", "setMintContract", params=[mint_address], network=nre.network)
