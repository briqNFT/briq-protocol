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

    return (starknet, briq_factory)


@pytest_asyncio.fixture
async def factory(factory_root):
    [starknet, briq_factory] = factory_root
    state = Starknet(state=starknet.state.copy())
    return SimpleNamespace(
        starknet=state,
        briq_factory=proxy_contract(state, briq_factory),
    )

import matplotlib.pyplot as plt

@pytest.mark.asyncio
async def test_chart(factory):
    await factory.briq_factory.initialise(0, 0, 0).execute()

    xs = [t for t in range(0, 300000, 300000//100)]
    ys = [(await factory.briq_factory.get_price_at_t(t * 10**18, 1).call()).result.price / 10**18 for t in xs]
    ys2 = [(await factory.briq_factory.get_price_at_t(t * 10**18, 200).call()).result.price / 10**18 for t in xs]

    # Create a figure and a set of subplots
    fig, ax = plt.subplots()

    # Plot data
    ax.plot(xs, ys)
    ax.plot(xs, ys2)

    # Set labels for x and y axis
    ax.set_xlabel('X values')
    ax.set_ylabel('Y values')

    # Set a title for the plot
    ax.set_title('A simple line plot')

    # Display the plot
    plt.show()


@pytest.mark.asyncio
async def test_integrate(factory):
    await factory.briq_factory.initialise(0, 0, 0).execute()
    assert (await factory.briq_factory.get_current_t().call()).result.t == 0

    assert (await factory.briq_factory.get_price(1).call()).result.price == 10**11 + 10**14 / 2
    # For 1K briq,
    # prix before = 10**11
    # prix after = 10**11 + 10**14 * 1000
    # Average price is sum divided by 2, we buy 1000, so:
    expected_price = 1000 * ((10**11 + 10**14 * 1000) + 10**11) // 2
    assert (await factory.briq_factory.get_price(1000).call()).result.price == expected_price

    await factory.briq_factory.initialise(1000 * 10**18, 0, 0).execute(ADDRESS)
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
    await factory.briq_factory.initialise(10**18 * (10**12 - 1), 0, 0).execute()
    assert (await factory.briq_factory.get_price(1).call()).result.price == 10**11 + 10**14 // 2 + 10**14 * (10**12 - 1)

    # Price before: 10**11 + 10**14 * 10**12 - 1
    # Price after: 10**11 + 10**14 * 10**12 - 1 + 10**14 * (10**10 - 1)
    assert (await factory.briq_factory.get_price(10**10 - 1).call()).result.price == ((10**11 + 10**14 * (10**12 - 1)) + (
        (10**14 * (10**10 - 1)) // 2)) * (10**10 - 1)


@pytest.mark.asyncio
async def test_surge(factory):
    await factory.briq_factory.initialise(0, 0, 0).execute()
    assert (await factory.briq_factory.get_price(1).call()).result.price == 30000166666666

    await factory.briq_factory.initialise(0, 10000 * 10**18, 0).execute()
    assert (await factory.briq_factory.get_price(1).call()).result.price == 30000166666666 + 10**14 // 2

    await factory.briq_factory.initialise(0, 0, 0).execute()
    assert (await factory.briq_factory.get_price(10000).call()).result.price == 316666666650000000

    await factory.briq_factory.initialise(0, 5000 * 10**18, 0).execute()
    assert (await factory.briq_factory.get_price(10000).call()).result.price == 316666666650000000 + 5000 * (5000 * 10**14 // 2)

    await factory.briq_factory.initialise(0, 20000 * 10**18, 0).execute()
    assert (await factory.briq_factory.get_surge_t().call()).result.t == 20000 * 10**18

    factory.starknet.state.state.update_block_info(
        BlockInfo.create_for_testing(
            block_number=3,
            block_timestamp=3600*12
        )
    )

    # Has about halved in half a day.
    assert (await factory.briq_factory.get_surge_t().call()).result.t == 20000 * 10**18 - 2315 * 10**14 * 3600*12

    factory.starknet.state.state.update_block_info(
        BlockInfo.create_for_testing(
            block_number=3,
            block_timestamp=3600*52
        )
    )

    assert (await factory.briq_factory.get_surge_t().call()).result.t == 0


@pytest.mark.asyncio
async def test_actual(factory):

    erc20 = compile("vendor/openzeppelin/token/erc20/presets/ERC20Mintable.cairo")
    await factory.starknet.declare(contract_class=erc20)
    token_contract_eth = await factory.starknet.deploy(contract_class=erc20, constructor_calldata=[
        0x1,  # name: felt,
        0x1,  # symbol: felt,
        18,  # decimals: felt,
        0, 2 * 64,  # initial_supply: Uint256,
        ADDRESS,  # recipient: felt,
        ADDRESS  # owner: felt
    ])

    [briq_contract, _] = await declare_and_deploy(factory.starknet, "briq.cairo")

    # Hack:
    await briq_contract.setBoxAddress_(factory.briq_factory.contract_address).execute()

    await factory.briq_factory.initialise(0, 0, token_contract_eth.contract_address).execute()
    await factory.briq_factory.setBriqAddress_(briq_contract.contract_address).execute()

    with pytest.raises(StarkException, match="insufficient allowance"):
        await factory.briq_factory.buy(1000).execute(ADDRESS)

    await token_contract_eth.approve(factory.briq_factory.contract_address, (10**18, 0)).execute(ADDRESS)
    await factory.briq_factory.buy(1000).execute(ADDRESS)
