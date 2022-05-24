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
    briq_contract = await starknet.deploy(contract_def=compile("briq_impl.cairo"))
    set_contract = await starknet.deploy(contract_def=compile("set_impl.cairo"))
    box_contract = await starknet.deploy(contract_def=compile("box.cairo"))
    await set_contract.setBriqAddress_(briq_contract.contract_address).invoke()
    await set_contract.setBoxAddress_(box_contract.contract_address).invoke()
    await briq_contract.setSetAddress_(set_contract.contract_address).invoke()
    await box_contract.setSetAddress_(set_contract.contract_address).invoke()
    await briq_contract.mintFT_(ADDRESS, 0x1, 50).invoke()
    return [starknet, set_contract, briq_contract, box_contract]


def proxy_contract(state, contract):
    return StarknetContract(
        state=state.state,
        abi=contract.abi,
        contract_address=contract.contract_address,
        deploy_execution_info=contract.deploy_execution_info,
    )

@pytest_asyncio.fixture
async def factory(factory_root):
    [starknet, set_contract, briq_contract, box_contract] = factory_root
    state = Starknet(state=starknet.state.copy())
    return namedtuple('State', ['starknet', 'set_contract', 'briq_contract', 'box_contract'])(
        starknet=state,
        set_contract=proxy_contract(state, set_contract),
        briq_contract=proxy_contract(state, briq_contract),
        box_contract=proxy_contract(state, box_contract),
    )


def hash_token_id(owner: int, hint: int, uri):
    raw_tid = compute_hash_on_elements([owner, hint]) & ((2**251 - 1) - (2**59 - 1))
    if len(uri) == 2 and uri[1] < 2**59:
        raw_tid += uri[1]
    return raw_tid

@pytest.mark.asyncio
async def test_working(tmp_path, factory):
    state = factory
    TOKEN_HINT = 1234
    TOKEN_URI = [1234]
    BOX_TOKEN_ID = 1234
    SET_TOKEN_ID = hash_token_id(ADDRESS, TOKEN_HINT, TOKEN_URI)
    data = open(os.path.join(CONTRACT_SRC, "shape/shape_store.cairo"), "r").read() + '\n'
    data = data.replace("#DEFINE_SHAPE", f"""
    const SHAPE_LEN = 4

    shape_data:
    {to_shape_data('#ffaaff', 1, 2, -2, -6)}
    {to_shape_data('#aaffaa', 1, 4, -2, -6)}
    {to_shape_data('#aaffaa', 1, 5, -2, -6)}
    {to_shape_data('#aaffaa', 1, 6, -2, -6)}
    shape_data_end:
    nft_data:
    nft_data_end:
""")
    # write to a file so we can get error messages.
    open(tmp_path / "contract.cairo", "w").write(data)
    test_code = compile_starknet_files(files=[str(tmp_path / "contract.cairo")], disable_hint_validation=True, debug_info=True)
    shape_contract = await state.starknet.deploy(contract_def=test_code)

    await state.box_contract.mint_(ADDRESS, BOX_TOKEN_ID, shape_contract.contract_address).invoke(ADDRESS)

    await state.set_contract.assemble_with_box_(
        owner=ADDRESS,
        token_id_hint=TOKEN_HINT,
        uri=TOKEN_URI,
        fts=[(0x1, 4)],
        nfts=[],
        box_token_id=BOX_TOKEN_ID,
        shape=[
            compress_shape_item('#ffaaff', 0x1, 2, -2, -6, False),
            compress_shape_item('#aaffaa', 0x1, 4, -2, -6, False),
            compress_shape_item('#aaffaa', 0x1, 5, -2, -6, False),
            compress_shape_item('#aaffaa', 0x1, 6, -2, -6, False),
        ],
    ).invoke(ADDRESS)
    assert (await state.set_contract.ownerOf_(SET_TOKEN_ID).call()).result.owner == ADDRESS
    assert (await state.briq_contract.balanceOfMaterial_(ADDRESS, 0x1).call()).result.balance == 46
    assert (await state.box_contract.ownerOf_(BOX_TOKEN_ID).call()).result.owner == SET_TOKEN_ID

    with pytest.raises(StarkException):
        await state.set_contract.disassemble_(
            owner=ADDRESS,
            token_id=SET_TOKEN_ID,
            fts=[(0x1, 4)],
            nfts=[],
        ).invoke(ADDRESS)
    await state.set_contract.disassemble_with_box_(
        owner=ADDRESS,
        token_id=SET_TOKEN_ID,
        fts=[(0x1, 4)],
        nfts=[],
        box_token_id=BOX_TOKEN_ID
    ).invoke(ADDRESS)
    assert (await state.set_contract.ownerOf_(SET_TOKEN_ID).call()).result.owner == 0
    assert (await state.briq_contract.balanceOfMaterial_(ADDRESS, 0x1).call()).result.balance == 50
    assert (await state.box_contract.ownerOf_(BOX_TOKEN_ID).call()).result.owner == ADDRESS


@pytest.mark.asyncio
async def test_bad_shape(tmp_path, factory):
    state = factory
    TOKEN_HINT = 1234
    BOX_TOKEN_ID = 1234

    data = open(os.path.join(CONTRACT_SRC, "shape/shape_store.cairo"), "r").read() + '\n'
    data = data.replace("#DEFINE_SHAPE", f"""
    const SHAPE_LEN = 4

    shape_data:
    {to_shape_data('#ffaaff', 1, 2, -2, -6)}
    {to_shape_data('#aaffaa', 1, 4, -2, -6)}
    {to_shape_data('#aaffaa', 1, 5, -2, -6)}
    {to_shape_data('#aaffaa', 1, 6, -2, -6)}
    shape_data_end:
    nft_data:
    nft_data_end:
""")
    # write to a file so we can get error messages.
    open(tmp_path / "contract.cairo", "w").write(data)
    test_code = compile_starknet_files(files=[str(tmp_path / "contract.cairo")], disable_hint_validation=True, debug_info=True)
    shape_contract = await state.starknet.deploy(contract_def=test_code)

    await state.box_contract.mint_(ADDRESS, BOX_TOKEN_ID, shape_contract.contract_address).invoke(ADDRESS)

    with pytest.raises(StarkException, match="Shapes do not match"):
        await state.set_contract.assemble_with_box_(
            owner=ADDRESS,
            token_id_hint=TOKEN_HINT,
            uri=[1234],
            fts=[(0x1, 4)],
            nfts=[],
            box_token_id=BOX_TOKEN_ID,
            shape=[
                compress_shape_item('#ffaaff', 0x1, 2, -2, -6, False),
                compress_shape_item('#aaffaa', 0x1, 5, -2, -6, False),
                compress_shape_item('#aaffaa', 0x1, 4, -2, -6, False),
                compress_shape_item('#aaffaa', 0x1, 6, -2, -6, False),
            ],
        ).invoke(ADDRESS)


@pytest.mark.asyncio
async def test_bad_number(tmp_path, factory):
    state = factory
    TOKEN_HINT = 1234
    BOX_TOKEN_ID = 1234

    data = open(os.path.join(CONTRACT_SRC, "shape/shape_store.cairo"), "r").read() + '\n'
    data = data.replace("#DEFINE_SHAPE", f"""
    const SHAPE_LEN = 4

    shape_data:
    {to_shape_data('#ffaaff', 1, 2, -2, -6)}
    {to_shape_data('#aaffaa', 1, 4, -2, -6)}
    {to_shape_data('#aaffaa', 1, 5, -2, -6)}
    {to_shape_data('#aaffaa', 1, 6, -2, -6)}
    shape_data_end:
    nft_data:
    nft_data_end:
""")
    # write to a file so we can get error messages.
    open(tmp_path / "contract.cairo", "w").write(data)
    test_code = compile_starknet_files(files=[str(tmp_path / "contract.cairo")], disable_hint_validation=True, debug_info=True)
    shape_contract = await state.starknet.deploy(contract_def=test_code)

    await state.box_contract.mint_(ADDRESS, BOX_TOKEN_ID, shape_contract.contract_address).invoke(ADDRESS)

    with pytest.raises(StarkException, match="Wrong number of briqs in shape"):
        await state.set_contract.assemble_with_box_(
            owner=ADDRESS,
            token_id_hint=TOKEN_HINT,
            uri=[1234],
            fts=[(0x1, 3)],
            nfts=[],
            box_token_id=BOX_TOKEN_ID,
            shape=[
                compress_shape_item('#ffaaff', 0x1, 2, -2, -6, False),
                compress_shape_item('#aaffaa', 0x1, 4, -2, -6, False),
                compress_shape_item('#aaffaa', 0x1, 5, -2, -6, False),
                compress_shape_item('#aaffaa', 0x1, 6, -2, -6, False),
            ],
        ).invoke(ADDRESS)

    with pytest.raises(StarkException, match="Wrong number of briqs in shape"):
        await state.set_contract.assemble_with_box_(
            owner=ADDRESS,
            token_id_hint=TOKEN_HINT,
            uri=[1234],
            fts=[(0x1, 5)],
            nfts=[],
            box_token_id=BOX_TOKEN_ID,
            shape=[
                compress_shape_item('#ffaaff', 0x1, 2, -2, -6, False),
                compress_shape_item('#aaffaa', 0x1, 4, -2, -6, False),
                compress_shape_item('#aaffaa', 0x1, 5, -2, -6, False),
                compress_shape_item('#aaffaa', 0x1, 6, -2, -6, False),
            ],
        ).invoke(ADDRESS)
