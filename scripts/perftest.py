import os

from nile.nre import NileRuntimeEnvironment
from starkware.cairo.lang.compiler.test_utils import short_string_to_felt

from generators.shape_utils import compress_shape_item, compress_long_shape_item

def flatten(t):
    return [item for sublist in t for item in sublist]

def run(nre: NileRuntimeEnvironment):
    if nre.network != "127.0.0.1":
        print("Error: should run on 127.0.0.1")
        exit(1)

    briq_interface_address, briq_abi = nre.get_deployment("briq_interface")
    set_interface_address, set_abi = nre.get_deployment("set_interface")

    # NB -> Might have to manually tweak ABIs in the file.
    briq, _ = nre.get_deployment("briq_proxy_")
    set, _ = nre.get_deployment("set_proxy_")

    os.environ["toto"] = "123456"
    account = nre.get_or_deploy_account("toto")

    nre.invoke(briq, "mintFT", [account.address, "1", "100"])

    print(account.send(set, "assemble_with_shape_", [
        int(account.address, 16), "545",
        1, 1, 50,
        0,
        1, "1234",
        50, *flatten([list(compress_shape_item("#ffaaff", 1, i, 0, 0)) for i in range(50)]),
        120
    ]))

    print(account.send(set, "assemble_with_shape_long_", [
        int(account.address, 16), "545",
        1, 1, 50,
        0,
        1, "1234",
        50, *flatten([list(compress_long_shape_item("#ffaaff", 1, i, 0, 0)) for i in range(50)]),
        120
    ]))

    print('starknet get_transaction_receipt --feeder_gateway_url="http://127.0.0.1:5000" --hash ')
