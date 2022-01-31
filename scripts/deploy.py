from nile.core.account import account_raw_execute, account_send, account_setup

import os

os.environ["SIGNER"] = "123456"

def run(nre):
    signer = account_setup("SIGNER", nre.network)
    print(f"Signer account: {signer.account}")

    briq_proxy, abi = nre.deploy("proxy_briq_backend", arguments=[signer.account], alias="proxy_briq_backend")
    set_proxy, abi = nre.deploy("proxy_set_backend", arguments=[signer.account], alias="proxy_set_backend")

    briq_address, abi = nre.deploy("briq_backend", arguments=[briq_proxy], alias="briq_backend")
    set_address, abi = nre.deploy("set_backend", arguments=[set_proxy], alias="set_backend")
    print(f"Deployed briq to {briq_address}")
    print(f"Deployed set to {set_address}")

    account_send("SIGNER", "proxy_briq_backend", "setImplementation", params=[briq_address], network=nre.network)
    account_send("SIGNER", "proxy_briq_backend", "setSetBackendAddress", params=[set_address], network=nre.network)

    account_send("SIGNER", "proxy_set_backend", "setImplementation", params=[set_address], network=nre.network)
    account_send("SIGNER", "proxy_set_backend", "setBriqBackendAddress", params=[briq_address], network=nre.network)

    mint_address, abi = nre.deploy("mint", arguments=[briq_proxy, "1000"], alias="mint")
    account_send("SIGNER", "proxy_briq_backend", "setMintContract", params=[mint_address], network=nre.network)
