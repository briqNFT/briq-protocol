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

from .conftest import declare_and_deploy, hash_token_id


CONTRACT_SRC = os.path.join(os.path.dirname(__file__), "..", "contracts")

ADDRESS = 0xcafe
OTHER_ADDRESS = 0xd00d
MOCK_SHAPE_TOKEN = 0xdeadfade

BOX_ADDRESS = 0x1234


@pytest_asyncio.fixture(scope="module")
async def factory_root():
    starknet = await Starknet.empty()
    [briq_contract, _] = await declare_and_deploy(starknet, "briq.cairo")
    [set_contract, _] = await declare_and_deploy(starknet, "set_nft.cairo")
    [attributes_registry_contract, _] = await declare_and_deploy(starknet, "attributes_registry.cairo")
    await set_contract.setBriqAddress_(briq_contract.contract_address).execute()
    await set_contract.setAttributesRegistryAddress_(attributes_registry_contract.contract_address).execute()
    await briq_contract.setSetAddress_(set_contract.contract_address).execute()
    await attributes_registry_contract.setSetAddress_(set_contract.contract_address).execute()
    await attributes_registry_contract.setBoxAddress_(BOX_ADDRESS).execute()
    await briq_contract.mintFT_(ADDRESS, 0x1, 50).execute()
    return [starknet, set_contract, briq_contract, attributes_registry_contract]


def proxy_contract(state, contract):
    return StarknetContract(
        state=state.state,
        abi=contract.abi,
        contract_address=contract.contract_address,
        deploy_call_info=contract.deploy_call_info,
    )

@pytest_asyncio.fixture
async def factory(factory_root):
    [starknet, set_contract, briq_contract, attributes_registry_contract] = factory_root
    state = Starknet(state=starknet.state.copy())
    return namedtuple('State', ['starknet', 'set_contract', 'briq_contract', 'attributes_registry_contract'])(
        starknet=state,
        set_contract=proxy_contract(state, set_contract),
        briq_contract=proxy_contract(state, briq_contract),
        attributes_registry_contract=proxy_contract(state, attributes_registry_contract),
    )

@pytest.mark.asyncio
async def test_working(tmp_path, factory):
    state = factory
    TOKEN_HINT = 1234
    TOKEN_URI = [1234]
    ATTRIBUTES_REGISTRY_TOKEN_ID = 1234
    SET_TOKEN_ID = hash_token_id(ADDRESS, TOKEN_HINT, TOKEN_URI)
    data = open(os.path.join(CONTRACT_SRC, "shape/shape_store.cairo"), "r").read() + '\n'
    data = data.replace("// DEFINE_SHAPE", f"""
    const SHAPE_LEN = 4;

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
    shape_hash = (await state.starknet.declare(contract_class=test_code)).class_hash
    await state.attributes_registry_contract.mint_(ADDRESS, ATTRIBUTES_REGISTRY_TOKEN_ID, shape_hash).execute(BOX_ADDRESS)

    await state.set_contract.assemble_with_attributes_registry_(
        owner=ADDRESS,
        token_id_hint=TOKEN_HINT,
        uri=TOKEN_URI,
        fts=[(0x1, 4)],
        nfts=[],
        attributes_registry_token_id=ATTRIBUTES_REGISTRY_TOKEN_ID,
        shape=[
            compress_shape_item('#ffaaff', 0x1, 2, -2, -6, False),
            compress_shape_item('#aaffaa', 0x1, 4, -2, -6, False),
            compress_shape_item('#aaffaa', 0x1, 5, -2, -6, False),
            compress_shape_item('#aaffaa', 0x1, 6, -2, -6, False),
        ],
    ).execute(ADDRESS)
    assert (await state.set_contract.ownerOf_(SET_TOKEN_ID).call()).result.owner == ADDRESS
    assert (await state.briq_contract.balanceOfMaterial_(ADDRESS, 0x1).call()).result.balance == 46
    assert (await state.attributes_registry_contract.balanceOf_(ADDRESS, ATTRIBUTES_REGISTRY_TOKEN_ID).call()).result.balance == 0
    assert (await state.attributes_registry_contract.balanceOf_(SET_TOKEN_ID, ATTRIBUTES_REGISTRY_TOKEN_ID).call()).result.balance == 1


    with pytest.raises(StarkException):
        await state.set_contract.disassemble_(
            owner=ADDRESS,
            token_id=SET_TOKEN_ID,
            fts=[(0x1, 4)],
            nfts=[],
        ).execute(ADDRESS)
    await state.set_contract.disassemble_with_attributes_registry_(
        owner=ADDRESS,
        token_id=SET_TOKEN_ID,
        fts=[(0x1, 4)],
        nfts=[],
        attributes_registry_token_id=ATTRIBUTES_REGISTRY_TOKEN_ID
    ).execute(ADDRESS)
    assert (await state.set_contract.ownerOf_(SET_TOKEN_ID).call()).result.owner == 0
    assert (await state.briq_contract.balanceOfMaterial_(ADDRESS, 0x1).call()).result.balance == 50
    assert (await state.attributes_registry_contract.balanceOf_(ADDRESS, ATTRIBUTES_REGISTRY_TOKEN_ID).call()).result.balance == 1
    assert (await state.attributes_registry_contract.balanceOf_(SET_TOKEN_ID, ATTRIBUTES_REGISTRY_TOKEN_ID).call()).result.balance == 0


@pytest.mark.asyncio
async def test_bad_shape(tmp_path, factory):
    state = factory
    TOKEN_HINT = 1234
    ATTRIBUTES_REGISTRY_TOKEN_ID = 1234

    data = open(os.path.join(CONTRACT_SRC, "shape/shape_store.cairo"), "r").read() + '\n'
    data = data.replace("// DEFINE_SHAPE", f"""
    const SHAPE_LEN = 4;

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
    shape_hash = (await state.starknet.declare(contract_class=test_code)).class_hash
    await state.attributes_registry_contract.mint_(ADDRESS, ATTRIBUTES_REGISTRY_TOKEN_ID, shape_hash).execute(BOX_ADDRESS)

    with pytest.raises(StarkException, match="Shapes do not match"):
        await state.set_contract.assemble_with_attributes_registry_(
            owner=ADDRESS,
            token_id_hint=TOKEN_HINT,
            uri=[1234],
            fts=[(0x1, 4)],
            nfts=[],
            attributes_registry_token_id=ATTRIBUTES_REGISTRY_TOKEN_ID,
            shape=[
                compress_shape_item('#ffaaff', 0x1, 2, -2, -6, False),
                compress_shape_item('#aaffaa', 0x1, 5, -2, -6, False),
                compress_shape_item('#aaffaa', 0x1, 4, -2, -6, False),
                compress_shape_item('#aaffaa', 0x1, 6, -2, -6, False),
            ],
        ).execute(ADDRESS)


@pytest.mark.asyncio
async def test_bad_number(tmp_path, factory):
    state = factory
    TOKEN_HINT = 1234
    ATTRIBUTES_REGISTRY_TOKEN_ID = 1234

    data = open(os.path.join(CONTRACT_SRC, "shape/shape_store.cairo"), "r").read() + '\n'
    data = data.replace("// DEFINE_SHAPE", f"""
    const SHAPE_LEN = 4;

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
    shape_hash = (await state.starknet.declare(contract_class=test_code)).class_hash
    await state.attributes_registry_contract.mint_(ADDRESS, ATTRIBUTES_REGISTRY_TOKEN_ID, shape_hash).execute(BOX_ADDRESS)

    with pytest.raises(StarkException, match="Wrong number of briqs in shape"):
        await state.set_contract.assemble_with_attributes_registry_(
            owner=ADDRESS,
            token_id_hint=TOKEN_HINT,
            uri=[1234],
            fts=[(0x1, 3)],
            nfts=[],
            attributes_registry_token_id=ATTRIBUTES_REGISTRY_TOKEN_ID,
            shape=[
                compress_shape_item('#ffaaff', 0x1, 2, -2, -6, False),
                compress_shape_item('#aaffaa', 0x1, 4, -2, -6, False),
                compress_shape_item('#aaffaa', 0x1, 5, -2, -6, False),
                compress_shape_item('#aaffaa', 0x1, 6, -2, -6, False),
            ],
        ).execute(ADDRESS)

    with pytest.raises(StarkException, match="Wrong number of briqs in shape"):
        await state.set_contract.assemble_with_attributes_registry_(
            owner=ADDRESS,
            token_id_hint=TOKEN_HINT,
            uri=[1234],
            fts=[(0x1, 5)],
            nfts=[],
            attributes_registry_token_id=ATTRIBUTES_REGISTRY_TOKEN_ID,
            shape=[
                compress_shape_item('#ffaaff', 0x1, 2, -2, -6, False),
                compress_shape_item('#aaffaa', 0x1, 4, -2, -6, False),
                compress_shape_item('#aaffaa', 0x1, 5, -2, -6, False),
                compress_shape_item('#aaffaa', 0x1, 6, -2, -6, False),
            ],
        ).execute(ADDRESS)
