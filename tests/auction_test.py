from collections import namedtuple
import os
import pytest
import pytest_asyncio

from starkware.starknet.testing.starknet import Starknet
from starkware.starknet.testing.starknet import StarknetContract
from starkware.starknet.testing.contract import StarknetContractFunctionInvocation
from starkware.starkware_utils.error_handling import StarkException
from starkware.cairo.common.hash_state import compute_hash_on_elements
from starkware.starknet.public.abi import get_selector_from_name

from starkware.starknet.utils.api_utils import cast_to_felts
from starkware.starknet.compiler.compile import compile_starknet_files, compile_starknet_codes

from generators.shape_utils import to_shape_data, compress_shape_item

import asyncio


@pytest.fixture(scope="session")
def event_loop():
    return asyncio.get_event_loop()


CONTRACT_SRC = os.path.join(os.path.dirname(__file__), "..", "contracts")

ADDRESS = 0xcafe
OTHER_ADDRESS = 0xd00d
MOCK_SHAPE_TOKEN = 0xdeadfade


def compile(path):
    return compile_starknet_files(
        files=[os.path.join(CONTRACT_SRC, path)],
        debug_info=True,
        disable_hint_validation=True
    )


@pytest_asyncio.fixture(scope="module")
async def factory_root():
    starknet = await Starknet.empty()
    erc20 = compile("OZ/token/erc20/ERC20_Mintable.cairo")
    token_contract_eth = await starknet.deploy(contract_def=erc20, constructor_calldata=[
        0x1,  # name: felt,
        0x1,  # symbol: felt,
        18,  # decimals: felt,
        0, 2 * 64,  # initial_supply: Uint256,
        ADDRESS,  # recipient: felt,
        ADDRESS  # owner: felt
    ])
    token_contract_dai = await starknet.deploy(contract_def=erc20, constructor_calldata=[
        0x2,  # name: felt,
        0x2,  # symbol: felt,
        18,  # decimals: felt,
        0, 2 * 64,  # initial_supply: Uint256,
        ADDRESS,  # recipient: felt,
        ADDRESS  # owner: felt
    ])
    auction_contract = await starknet.deploy(contract_def=compile("auction/auction.cairo"))
    box_contract = await starknet.deploy(contract_def=compile("box.cairo"))
    return [starknet, auction_contract, box_contract, token_contract_eth, token_contract_dai]


def proxy_contract(state, contract):
    return StarknetContract(
        state=state.state,
        abi=contract.abi,
        contract_address=contract.contract_address,
        deploy_execution_info=contract.deploy_execution_info,
    )

@pytest_asyncio.fixture
async def factory(factory_root):
    [starknet, auction_contract, box_contract, token_contract_eth, token_contract_dai] = factory_root
    state = Starknet(state=starknet.state.copy())
    return namedtuple('State', ['starknet', 'auction_contract', 'box_contract', 'token_contract_eth', 'token_contract_dai'])(
        starknet=state,
        auction_contract=proxy_contract(state, auction_contract),
        box_contract=proxy_contract(state, box_contract),
        token_contract_eth=proxy_contract(state, token_contract_eth),
        token_contract_dai=proxy_contract(state, token_contract_dai),
    )

@pytest.mark.asyncio
async def test_bid(factory):
    with pytest.raises(StarkException, match="Bid greater than allowance"):
        await factory.auction_contract.make_bid(factory.auction_contract.BidData(
            payer=ADDRESS,
            payer_erc20_contract=factory.token_contract_eth.contract_address,
            box_token_id=0xfade,
            bid_amount=300
        )).invoke(ADDRESS)

    with pytest.raises(StarkException, match="Bid must be greater than 0"):
        await factory.auction_contract.make_bid(factory.auction_contract.BidData(
            payer=ADDRESS,
            payer_erc20_contract=factory.token_contract_eth.contract_address,
            box_token_id=0xfade,
            bid_amount=0
        )).invoke(ADDRESS)

    await factory.token_contract_eth.approve(factory.auction_contract.contract_address, (500, 0)).invoke(ADDRESS)

    with pytest.raises(StarkException, match="Bid greater than allowance"):
        await factory.auction_contract.make_bid(factory.auction_contract.BidData(
            payer=ADDRESS,
            payer_erc20_contract=factory.token_contract_eth.contract_address,
            box_token_id=0xfade,
            bid_amount=600
        )).invoke(ADDRESS)

    await factory.auction_contract.make_bid(factory.auction_contract.BidData(
        payer=ADDRESS,
        payer_erc20_contract=factory.token_contract_eth.contract_address,
        box_token_id=0xfade,
        bid_amount=500
    )).invoke(ADDRESS)

    events = factory.starknet.state.events

    assert factory.auction_contract.event_manager._selector_to_name[events[1].keys[0]] == 'Bid'
    assert events[1].data == [
        ADDRESS,
        factory.token_contract_eth.contract_address,
        0xfade,
        500,
    ]
