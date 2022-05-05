import os
import pytest
import pytest_asyncio

from starkware.starknet.testing.starknet import Starknet
from starkware.starknet.testing.starknet import StarknetContract
from starkware.starkware_utils.error_handling import StarkException
from starkware.cairo.common.hash_state import compute_hash_on_elements

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
    box_contract = await starknet.deploy(contract_def=compile("box.cairo"))
    set_mock = await starknet.deploy(contract_def=compile("mocks/set_mock.cairo"))
    shape_mock = await starknet.deploy(contract_def=compile("mocks/shape_mock.cairo"))
    await box_contract.setSetAddress_(set_mock.contract_address).invoke()
    await box_contract.mint_(MOCK_SHAPE_TOKEN, MOCK_SHAPE_TOKEN, shape_mock.contract_address).invoke()
    return (starknet, box_contract, shape_mock)

@pytest_asyncio.fixture
async def factory(factory_root):
    [starknet, a, b] = factory_root
    state = Starknet(state=starknet.state.copy())
    a = StarknetContract(
        state=state.state,
        abi=a.abi,
        contract_address=a.contract_address,
        deploy_execution_info=a.deploy_execution_info,
    )
    b = StarknetContract(
        state=state.state,
        abi=b.abi,
        contract_address=b.contract_address,
        deploy_execution_info=b.deploy_execution_info,
    )
    return (state, a, b)

@pytest.mark.asyncio
async def test_mint_transfer(factory):
    [_, box_contract, _] = factory
    TOKEN = 1
    await box_contract.mint_(ADDRESS, TOKEN, 2).invoke()
    await box_contract.transferFrom_(ADDRESS, OTHER_ADDRESS, TOKEN).invoke()


@pytest.mark.asyncio
async def test_shape(factory):
    [starknet, box_contract, _] = factory

    data = open(os.path.join(CONTRACT_SRC, "shape/shape_store.cairo"), "r").read() + '\n'
    data = data.replace("#DEFINE_SHAPE", f"""
    const SHAPE_LEN = 3

    shape_data:
    {to_shape_data('#ffaaff', 1, 4, -2, -6)}
    {to_shape_data('#ffaaff', 1, 4, 0, -6)}
    {to_shape_data('#ffaaff', 1, 4, 4, -6, True)}

    shape_data_end:
    nft_data:
    dw { 1 * 2 **64 + 1}
    nft_data_end:
""")
    test_code = compile_starknet_codes(codes=[(data, "test_code")])
    shape_contract = await starknet.deploy(contract_def=test_code)

    TOKEN = 1
    await box_contract.mint_(ADDRESS, TOKEN, shape_contract.contract_address).invoke()
    assert (await box_contract.get_shape_(TOKEN).call()).result.shape == [
        shape_contract.ShapeItem(*compress_shape_item(color='#ffaaff', material=1, x=4, y=-2, z=-6)),
        shape_contract.ShapeItem(*compress_shape_item(color='#ffaaff', material=1, x=4, y=0, z=-6)),
        shape_contract.ShapeItem(*compress_shape_item(color='#ffaaff', material=1, x=4, y=4, z=-6, has_token_id=True))
    ]
    assert (await box_contract.get_shape_(TOKEN).call()).result.nfts == [1 * 2 ** 64 + 1]

@pytest.mark.asyncio
async def test_mint_shape(factory):
    [_, box_contract, _] = factory
    await box_contract.assemble_with_shape_(owner=ADDRESS, token_id_hint=0x1,
        fts=[(1, 1)], nfts=[], shape=[box_contract.ShapeItem(*compress_shape_item(
            color="#ffaaff", material=1, x=0, y=4, z=-2
        ))], target_shape_token_id=MOCK_SHAPE_TOKEN,
        uri=[1234]).invoke(ADDRESS)

@pytest.mark.asyncio
async def test_mint_shape_nft(factory):
    [_, box_contract, _] = factory
    await box_contract.assemble_with_shape_(owner=ADDRESS, token_id_hint=0x1,
        fts=[(1, 2)], nfts=[1 * 2**64 + 2], shape=[box_contract.ShapeItem(*compress_shape_item(
            color="#ffaaff", material=1, x=0, y=4, z=-2
        )), box_contract.ShapeItem(*compress_shape_item(
            color="#ffaaff", material=2, x=0, y=5, z=-2, has_token_id=True
        )), box_contract.ShapeItem(*compress_shape_item(
            color="#ffaaff", material=1, x=0, y=6, z=-2
        ))], target_shape_token_id=MOCK_SHAPE_TOKEN,
        uri=[1234]).invoke(ADDRESS)

@pytest.mark.asyncio
async def test_mint_shape_nft_only(factory):
    [_, box_contract, _] = factory
    await box_contract.assemble_with_shape_(owner=ADDRESS, token_id_hint=0x1,
        fts=[], nfts=[1 * 2**64 + 2, 2 * 2**64 + 1], shape=[box_contract.ShapeItem(*compress_shape_item(
            color="#ffaaff", material=2, x=0, y=5, z=-2, has_token_id=True
        )), box_contract.ShapeItem(*compress_shape_item(
            color="#ffaaff", material=1, x=1, y=5, z=-2, has_token_id=True
        ))], target_shape_token_id=MOCK_SHAPE_TOKEN,
        uri=[1234]).invoke(ADDRESS)

@pytest.mark.asyncio
async def test_mint_shape_multimat(factory):
    [_, box_contract, _] = factory
    await box_contract.assemble_with_shape_(owner=ADDRESS, token_id_hint=0x1,
        fts=[(1, 2), (2, 1)], nfts=[], shape=[box_contract.ShapeItem(*compress_shape_item(
            color="#ffaaff", material=1, x=0, y=4, z=-2
        )), box_contract.ShapeItem(*compress_shape_item(
            color="#ffaaff", material=2, x=1, y=4, z=-2
        )), box_contract.ShapeItem(*compress_shape_item(
            color="#ffaaff", material=1, x=2, y=4, z=-2
        ))], target_shape_token_id=MOCK_SHAPE_TOKEN,
        uri=[1234]).invoke(ADDRESS)

@pytest.mark.asyncio
async def test_mint_shape_bad_noshape(factory):
    [_, box_contract, _] = factory
    with pytest.raises(StarkException, match="Wrong number of briqs in shape"):
        await box_contract.assemble_with_shape_(owner=ADDRESS, token_id_hint=0x1,
            fts=[(1, 1)], nfts=[], shape=[], target_shape_token_id=MOCK_SHAPE_TOKEN,
            uri=[1234]).invoke(ADDRESS)

@pytest.mark.asyncio
async def test_mint_shape_bad_bad_material(factory):
    [_, box_contract, _] = factory
    with pytest.raises(StarkException, match="Wrong number of briqs in shape"):
        await box_contract.assemble_with_shape_(owner=ADDRESS, token_id_hint=0x1,
            fts=[(1, 1)], nfts=[], shape=[box_contract.ShapeItem(*compress_shape_item(
                color="#ffaaff", material=2, x=0, y=4, z=-2
            ))], target_shape_token_id=MOCK_SHAPE_TOKEN,
            uri=[1234]).invoke(ADDRESS)

@pytest.mark.asyncio
async def test_mint_shape_bad_repeated_nft(factory):
    [starknet, box_contract, _] = factory
    # This goes through despite the repeated NFT because of the mock
    await box_contract.assemble_with_shape_(owner=ADDRESS, token_id_hint=0x1,
        fts=[], nfts=[1 * 2**64 + 2, 1 * 2**64 + 2], shape=[box_contract.ShapeItem(*compress_shape_item(
            color="#ffaaff", material=2, x=0, y=4, z=-2, has_token_id=True
        )), box_contract.ShapeItem(*compress_shape_item(
            color="#ffaaff", material=2, x=0, y=5, z=-2, has_token_id=True
        ))], target_shape_token_id=MOCK_SHAPE_TOKEN,
        uri=[1234]).invoke(ADDRESS)

    # But if we don't mock, then it'll fail.
    briq = await starknet.deploy(contract_def=compile("briq_impl.cairo"))
    set = await starknet.deploy(contract_def=compile("set_impl.cairo"))
    await briq.setSetAddress_(set.contract_address).invoke()
    await set.setBriqAddress_(briq.contract_address).invoke()
    await box_contract.setSetAddress_(set.contract_address).invoke()
    with pytest.raises(StarkException, match="assert sender = curr_owner"):
        await box_contract.assemble_with_shape_(owner=ADDRESS, token_id_hint=0x1,
            fts=[], nfts=[1 * 2**64 + 2, 1 * 2**64 + 2], shape=[box_contract.ShapeItem(*compress_shape_item(
                color="#ffaaff", material=2, x=0, y=4, z=-2, has_token_id=True
            )), box_contract.ShapeItem(*compress_shape_item(
                color="#ffaaff", material=2, x=0, y=5, z=-2, has_token_id=True
            ))], target_shape_token_id=MOCK_SHAPE_TOKEN,
            uri=[1234]).invoke(ADDRESS)

@pytest.mark.asyncio
async def test_mint_shape_bad_not_enough(factory):
    [_, box_contract, _] = factory
    with pytest.raises(StarkException, match="Wrong number of briqs in shape"):
        await box_contract.assemble_with_shape_(owner=ADDRESS, token_id_hint=0x1,
            fts=[(1, 2)], nfts=[], shape=[box_contract.ShapeItem(*compress_shape_item(
                color="#ffaaff", material=1, x=0, y=4, z=-2
            ))], target_shape_token_id=MOCK_SHAPE_TOKEN,
            uri=[1234]).invoke(ADDRESS)

@pytest.mark.asyncio
async def test_mint_shape_bad_too_many(factory):
    [_, box_contract, _] = factory
    with pytest.raises(StarkException, match="Wrong number of briqs in shape"):
        await box_contract.assemble_with_shape_(owner=ADDRESS, token_id_hint=0x1,
            fts=[(1, 1)], nfts=[], shape=[box_contract.ShapeItem(*compress_shape_item(
                color="#ffaaff", material=1, x=0, y=4, z=-2
            )), box_contract.ShapeItem(*compress_shape_item(
                color="#ffaaff", material=1, x=1, y=4, z=-2
            ))], target_shape_token_id=MOCK_SHAPE_TOKEN,
            uri=[1234]).invoke(ADDRESS)
