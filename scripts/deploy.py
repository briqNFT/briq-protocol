from nile.core.account import account_raw_execute, account_send, account_setup

import os

os.environ["SIGNER"] = "123456"

def run(nre):
    signer = account_setup("SIGNER", nre.network)
    print(f"Signer account: {signer.account}")

    briq_impl, abi = nre.deploy("briq_impl", arguments=[], alias="briq_impl")
    set_impl, abi = nre.deploy("set_impl", arguments=[], alias="set_impl")

    briq_address, abi = nre.deploy("_proxy", arguments=[signer.account, briq_impl], alias="briq")
    set_address, abi = nre.deploy("_proxy", arguments=[signer.account, set_impl], alias="set")

    print(f"Deployed briq to {briq_address}")
    print(f"Deployed set to {set_address}")

    account_send("SIGNER", "briq", "setSetAddress", params=[set_address], network=nre.network)
    account_send("SIGNER", "set", "setBriqAddress", params=[briq_address], network=nre.network)

    mint_address, abi = nre.deploy("mint", arguments=[briq_address, "1000"], alias="mint")
    account_send("SIGNER", "briq", "setMintContract", params=[mint_address], network=nre.network)
