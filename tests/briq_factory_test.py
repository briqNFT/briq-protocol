from types import SimpleNamespace
import pytest
import pytest_asyncio

from starkware.starknet.testing.starknet import Starknet
from starkware.starkware_utils.error_handling import StarkException
from starkware.starknet.business_logic.state.state_api_objects import BlockInfo

from .conftest import declare, declare_and_deploy, proxy_contract, compile

ADDRESS = 0xcafe
OTHER_ADDRESS = 0xfade
DISALLOWED_ADDRESS = 0xdead


@pytest_asyncio.fixture(scope="session")
async def factory_root():
    starknet = await Starknet.empty()

    [briq_factory, _] = await declare_and_deploy(starknet, "briq_factory.cairo")

    erc20 = compile("vendor/openzeppelin/token/erc20/presets/ERC20Mintable.cairo")
    await starknet.declare(contract_class=erc20)
    token_contract_eth = await starknet.deploy(contract_class=erc20, constructor_calldata=[
        0x1,  # name: felt,
        0x1,  # symbol: felt,
        18,  # decimals: felt,
        0, 2 * 64,  # initial_supply: Uint256,
        ADDRESS,  # recipient: felt,
        ADDRESS  # owner: felt
    ])
    await token_contract_eth.transfer(OTHER_ADDRESS, (100000, 0)).execute(ADDRESS)

    return (starknet, briq_factory, token_contract_eth)


@pytest_asyncio.fixture
async def factory(factory_root):
    [starknet, briq_factory, token_contract_eth] = factory_root
    state = Starknet(state=starknet.state.copy())
    return SimpleNamespace(
        starknet=state,
        briq_factory=proxy_contract(state, briq_factory),
        token_contract_eth=proxy_contract(state, token_contract_eth),
    )


@pytest.mark.asyncio
async def test_integrate(factory):
    await factory.briq_factory.initialise(0).execute(ADDRESS)
    assert (await factory.briq_factory.get_current_t().call()).result.t == 0

    assert (await factory.briq_factory.get_price(1).call()).result.price == 10**11 + 10**14 / 2
    # For 1K briq,
    # prix before = 10**11
    # prix after = 10**11 + 10**14 * 1000
    # Average price is sum divided by 2, we buy 1000, so:
    expected_price = 1000 * ((10**11 + 10**14 * 1000) + 10**11) // 2
    assert (await factory.briq_factory.get_price(1000).call()).result.price == expected_price

    await factory.briq_factory.initialise(1000 * 10**18).execute(ADDRESS)
    assert (await factory.briq_factory.get_current_t().call()).result.t == 1000 * 10**18

    factory.starknet.state.state.update_block_info(
        BlockInfo.create_for_testing(
            block_number=3,
            block_timestamp=10000
        )
    )
    assert (await factory.briq_factory.get_current_t().call()).result.t == 1000 * 10**18 - 10**10 * 10000


@pytest.mark.asyncio
async def test_overflows(factory):
    # Try wuth the maximum value I allow and ensure that we don't get overflows.
    await factory.briq_factory.initialise(10**18 * (10**12 - 1)).execute(ADDRESS)
    assert (await factory.briq_factory.get_price(1).call()).result.price == 10**11 + 10**14 // 2 + 10**14 * (10**12 - 1)

    # Price before: 10**11 + 10**14 * 10**12 - 1
    # Price after: 10**11 + 10**14 * 10**12 - 1 + 10**14 * (10**10 - 1)
    assert (await factory.briq_factory.get_price(10**10 - 1).call()).result.price == ((10**11 + 10**14 * (10**12 - 1)) + (
        (10**14 * (10**10 - 1)) // 2)) * (10**10 - 1)
