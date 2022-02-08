import json
import os
import subprocess
import urllib.request
import time

import requests

#from starknet_py.net import Client
#from starknet_py.net.networks import Network, MAINNET, TESTNET
#from starknet_py.net.models.chains import chain_from_network
#from starknet_py.contract import Contract


from starkware.starknet.public.abi import (
    DEFAULT_ENTRY_POINT_SELECTOR,
    get_selector_from_name
)

import pytest

@pytest.fixture(scope="session")
def node():
    process = subprocess.Popen(["starknet-devnet"])
    i = 0
    while i < 10:
        try:
            urllib.request.urlopen("http://localhost:5000/is_alive").getcode()
            break
        except:
            i += 1
            time.sleep(1)
            continue
    yield
    process.terminate()
    process.wait()
    print("Correctly killed Nile Node")

@pytest.fixture(scope="session")
def deploy(node):
    try:
        os.unlink("localhost.deployments.txt")
    except:
        pass
    with open("localhost.accounts.json", "w") as f:
        f.write("{}")
    subprocess.run(["nile", "run", "scripts/deploy.py"])

# Just a passing test to say we're started on CLI.
def test_inte_tests_started(node):
    return


# TODO: use starknet.py instead, with a custom wallet.
def test_integration(deploy):
    #client = Client("http://localhost:5000", chain_from_network(TESTNET, None))
    #ctrct = Contract()
    #contractData = {}
    #with open("localhost.deployments.txt") as f:
    #    data = [info.split(":") for info in f.read().split("\n")]
    #    contractData = {d[2]: {"abi": d[1], "address": d[0]} for d in data}

    accts = json.load(open("localhost.accounts.json", "r"))
    addr = ""
    for pkey in accts:
        addr = accts[pkey]["address"]

    os.environ["SIGNER"] = "123456"
    subprocess.run(["nile", "send", "SIGNER", "mint", "mintAmount", addr, "0x150"])
    
    assert subprocess.run(["nile", "call", "briq_backend", "balanceOf", addr, "1"], capture_output=True).stdout == b'336\n'
