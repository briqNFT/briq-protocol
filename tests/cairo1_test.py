from collections import namedtuple
from importlib.metadata import entry_points
import os
from types import SimpleNamespace
from typing import Any
import pytest
import pytest_asyncio

from starkware.starknet.testing.starknet import Starknet
from starkware.starkware_utils.error_handling import StarkException
from starkware.starknet.business_logic.state.state_api_objects import BlockInfo

from .conftest import declare, declare_and_deploy, proxy_contract, compile


from starkware.starknet.compiler.compile import compile_starknet_files
from starkware.starknet.testing.starknet import StarknetContract
from starkware.cairo.common.hash_state import compute_hash_on_elements

from briq_protocol.generate_shape import generate_shape_code


ADDRESS = 0xcafe
OTHER_ADDRESS = 0xfade
DISALLOWED_ADDRESS = 0xdead


CONTRACT_SRC = os.path.join(os.path.dirname(__file__), "..", "contract_c1")
VENDOR_SRC = os.path.join(os.path.dirname(__file__), "..", "contract_c1", "vendor")

@pytest_asyncio.fixture(scope="session")
async def factory_root():
    starknet = None
    from starknet_py.contract import Contract

    from starknet_py.hash.address import compute_address
    from starknet_py.net.account.account import Account
    from starknet_py.net.gateway_client import GatewayClient
    from starknet_py.net.models import StarknetChainId
    from starknet_py.net.networks import TESTNET
    from starknet_py.net.signer.stark_curve_signer import KeyPair

    # First, make sure to generate private key and salt
    private_key = 0xb73fc4c6bd6067ca8f3c305e5cef9fe1    
    key_pair = KeyPair.from_private_key(private_key)

    #Address: 0x2880f315c1f3d0c187a1eaaeb696dde1c40df40a6d436eb86f2838b9a544cc6
    #Public key: 0x74dfc554c85a82947c3ee6e8d1f59600321a5502b6c90ae0b201e606b362280
    #Private key: 0xb73fc4c6bd6067ca8f3c305e5cef9fe1

    client = GatewayClient(net="http://localhost:5050")
    chain = StarknetChainId.TESTNET

    account = Account(address=0x2880f315c1f3d0c187a1eaaeb696dde1c40df40a6d436eb86f2838b9a544cc6, key_pair=key_pair, client=client, chain=chain)

    from starknet_py.hash.casm_class_hash import compute_casm_class_hash
    from starknet_py.net.schemas.gateway import CasmClassSchema
    from starknet_py.common import create_casm_class

    with open("target/release/target/release/briq_protocol_AttributesRegistry.sierra.json", "r") as casm:
        casm_class = create_casm_class(casm)

    # Compute Casm class hash
    casm_class_hash = compute_casm_class_hash(casm_class)

    # Create Declare v2 transaction
    with open("target/release/briq_protocol_AttributesRegistry.sierra.json", "r") as sierra:
        declare_v2_transaction = await account.sign_declare_v2_transaction(
            compiled_contract=sierra.read(),
            compiled_class_hash=casm_class_hash,
            max_fee=9879867867876987867,
        )

    # Send Declare v2 transaction
    resp = await account.client.declare(transaction=declare_v2_transaction)
    await account.client.wait_for_tx(resp.transaction_hash)

    sierra_class_hash = resp.class_hash

    # To interact with just deployed contract get its instance from the deploy_result
    contract = deploy_result.deployed_contract

    # Now, any of the contract functions can be called
    return (starknet, None, None)


@pytest_asyncio.fixture
async def factory(factory_root):
    [starknet, auction_contract, token_contract_eth] = factory_root
    state = Starknet(state=starknet.state.copy())
    return SimpleNamespace(
        starknet=state,
        auction_contract=proxy_contract(state, auction_contract),
        token_contract_eth=proxy_contract(state, token_contract_eth),
    )


def test_cairo1(factory):
    pass
