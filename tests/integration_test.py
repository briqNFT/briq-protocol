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
THIRD_ADDRESS = 0xfade

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
    auction_contract = await starknet.deploy(contract_def=compile("auction/auction.cairo"))
    booklet_contract = await starknet.deploy(contract_def=compile("booklet.cairo"))
    set_contract = await starknet.deploy(contract_def=compile("set_interface.cairo"))
    briq_contract = await starknet.deploy(contract_def=compile("briq_interface.cairo"))

    await set_contract.setBriqAddress_(briq_contract.contract_address).invoke()
    await set_contract.setBookletAddress_(booklet_contract.contract_address).invoke()
    await briq_contract.setSetAddress_(set_contract.contract_address).invoke()
    await booklet_contract.setSetAddress_(set_contract.contract_address).invoke()
    
    return [starknet, auction_contract, booklet_contract, token_contract_eth, set_contract, briq_contract]


def proxy_contract(state, contract):
    return StarknetContract(
        state=state.state,
        abi=contract.abi,
        contract_address=contract.contract_address,
        deploy_execution_info=contract.deploy_execution_info,
    )

@pytest_asyncio.fixture
async def factory(factory_root):
    [starknet, auction_contract, booklet_contract, token_contract_eth, set_contract, briq_contract] = factory_root
    state = Starknet(state=starknet.state.copy())
    return namedtuple('State', ['starknet', 'auction_contract', 'booklet_contract', 'token_contract_eth', 'set_contract', 'briq_contract'])(
        starknet=state,
        auction_contract=proxy_contract(state, auction_contract),
        booklet_contract=proxy_contract(state, booklet_contract),
        token_contract_eth=proxy_contract(state, token_contract_eth),
        set_contract=proxy_contract(state, set_contract),
        briq_contract=proxy_contract(state, briq_contract),
    )


async def deploy_shape(starknet, shape_data):
    data = open(os.path.join(CONTRACT_SRC, "shape/shape_store.cairo"), "r").read() + '\n'
    shape_data_str = '\n'.join(shape_data)
    shape = data.replace("#DEFINE_SHAPE", f"""
    const SHAPE_LEN = {len(shape_data)}

    shape_data:
    {shape_data_str}
    shape_data_end:
    nft_data:
    nft_data_end:
""")
    test_code = compile_starknet_codes(codes=[(shape, "shape_code")], disable_hint_validation=True)
    return await starknet.deploy(contract_def=test_code)

from generators.generate_box import generate_box


def hash_token_id(owner: int, hint: int, uri):
    raw_tid = compute_hash_on_elements([owner, hint]) & ((2**251 - 1) - (2**59 - 1))
    if len(uri) == 2 and uri[1] < 2**59:
        raw_tid += uri[1]
    return raw_tid


@pytest.mark.asyncio
async def test_everything(tmp_path, factory):
    # Deploy two shape contracts
    shape_basic = await deploy_shape(factory.starknet, [
        to_shape_data('#ffaaff', 0x1, -2, 0, 2),
        to_shape_data('#ffaaff', 0x1, -1, 0, 2),
        to_shape_data('#ffaaff', 0x1, 0, 0, 2),
    ])
    shape_bimat = await deploy_shape(factory.starknet, [
        to_shape_data('#ffaaff', 0x1, -2, 1, 2),
        to_shape_data('#ffaaff', 0x4, -1, 1, 2),
        to_shape_data('#ffaaff', 0x1, 0, 1, 2),
    ])
    box_code = generate_box(briq_data={
        1: {
            0x1: 3
        },
        2: {
            0x1: 2,
            0x4: 1
        }
    }, shape_data={
        0x1: shape_basic.contract_address,
        0x2: shape_bimat.contract_address,
    }, booklet_address=factory.booklet_contract.contract_address, briq_address=factory.briq_contract.contract_address)
    print(box_code)
    (tmp_path / 'contracts' / 'box_erc1155').mkdir(parents=True, exist_ok=True)
    open(tmp_path / 'contracts' / 'box_erc1155' / 'data.cairo', "w").write(box_code)
    box_code = compile_starknet_files(files=[os.path.join(CONTRACT_SRC, 'box.cairo')], disable_hint_validation=True, debug_info=True, cairo_path=[str(tmp_path)])

    box_contract = await factory.starknet.deploy(contract_def=box_code)

    await box_contract.setBookletAddress_(factory.booklet_contract.contract_address).invoke()
    await box_contract.setBriqAddress_(factory.briq_contract.contract_address).invoke()
    await factory.booklet_contract.setBoxAddress_(box_contract.contract_address).invoke()
    await factory.briq_contract.setBoxAddress_(box_contract.contract_address).invoke()

    # Let's mint some boxes
    await box_contract.mint_(ADDRESS, 0x1, 10).invoke()
    await box_contract.mint_(ADDRESS, 0x2, 4).invoke()
    with pytest.raises(StarkException):
        await box_contract.mint_(ADDRESS, 0x3, 1).invoke()

    # TODO -> Auction
    await box_contract.safeTransferFrom_(ADDRESS, OTHER_ADDRESS, 0x1, 1, []).invoke(ADDRESS)
    await box_contract.safeTransferFrom_(ADDRESS, OTHER_ADDRESS, 0x2, 1, []).invoke(ADDRESS)

    assert (await factory.briq_contract.balanceOfMaterial_(OTHER_ADDRESS, 0x1).call()).result.balance == 0

    await box_contract.unbox_(OTHER_ADDRESS, 0x1).invoke(OTHER_ADDRESS)

    assert (await factory.booklet_contract.balanceOf_(OTHER_ADDRESS, 0x1).call()).result.balance == 1
    assert (await factory.briq_contract.balanceOfMaterial_(OTHER_ADDRESS, 0x1).call()).result.balance == 3

    await box_contract.unbox_(OTHER_ADDRESS, 0x2).invoke(OTHER_ADDRESS)
    assert (await factory.booklet_contract.balanceOf_(OTHER_ADDRESS, 0x2).call()).result.balance == 1
    assert (await factory.briq_contract.balanceOfMaterial_(OTHER_ADDRESS, 0x1).call()).result.balance == 5
    assert (await factory.briq_contract.balanceOfMaterial_(OTHER_ADDRESS, 0x4).call()).result.balance == 1

    set_token_id_a = hash_token_id(OTHER_ADDRESS, 0x1234, [1234])

    await factory.set_contract.assemble_with_booklet_(
        owner=OTHER_ADDRESS,
        token_id_hint=0x1234,
        uri=[1234],
        fts=[(0x1, 3)],
        nfts=[],
        booklet_token_id=0x1,
        shape=[
            compress_shape_item('#ffaaff', 0x1, -2, 0, 2, False),
            compress_shape_item('#ffaaff', 0x1, -1, 0, 2, False),
            compress_shape_item('#ffaaff', 0x1, 0, 0, 2, False),
        ]
    ).invoke(OTHER_ADDRESS)

    assert (await factory.booklet_contract.balanceOf_(OTHER_ADDRESS, 0x1).call()).result.balance == 0
    assert (await factory.briq_contract.balanceOfMaterial_(OTHER_ADDRESS, 0x1).call()).result.balance == 2
    assert (await factory.briq_contract.balanceOfMaterial_(OTHER_ADDRESS, 0x4).call()).result.balance == 1

    assert (await factory.booklet_contract.balanceOf_(set_token_id_a, 0x1).call()).result.balance == 1
    assert (await factory.briq_contract.balanceOfMaterial_(set_token_id_a, 0x1).call()).result.balance == 3
