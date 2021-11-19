from typing import Any, Union

from starkware.crypto.signature.signature import pedersen_hash, sign
from starkware.starknet.testing.contract import StarknetContract
from starkware.starknet.compiler.compile import get_selector_from_name
from starkware.starknet.services.api.gateway.transaction import InvokeFunction
from services.external_api.base_client import RetryConfig
from starkware.starknet.services.api.feeder_gateway.feeder_gateway_client import FeederGatewayClient
from starkware.starknet.services.api.gateway.gateway_client import GatewayClient

from starkware.cairo.lang.tracer.tracer_data import field_element_repr
from starkware.starknet.definitions import fields

retry_config = RetryConfig(n_retries=1)
client = GatewayClient(url="https://alpha4.starknet.io/gateway/", retry_config=retry_config)
feeder_client = FeederGatewayClient(url="https://alpha4.starknet.io/feeder_gateway/", retry_config=retry_config)


def set_gateway(url: str):
    global client
    global feeder_client
    print(f"setting gateway to {url}")
    client = GatewayClient(url=url + "gateway/", retry_config=retry_config)
    feeder_client = FeederGatewayClient(url=url + "feeder_gateway/", retry_config=retry_config)


def felt_formatter(hex_felt: str) -> Union[str, int]:
    try:
        return int(hex_felt, 16)
    except Exception:
        return field_element_repr(val=int(hex_felt, 16), prime=fields.FeltField.upper_bound)


class FuncInvocation:
    def __init__(self, tx):
        self.tx = tx

    async def call(self) -> Union[Union[str, int], list[Union[str, int]]]:
        res = await feeder_client.call_contract(self.tx, None)
        res = list(map(felt_formatter, res['result']))
        if len(res) == 1:
            return res[0]
        return res

    async def invoke(self):
        print(f"invoking with {self.tx}")
        return await client.add_transaction(self.tx)


class ContractWrapper:
    def __init__(self, abi_json: list[Any], address: str) -> None:
        self.contract = StarknetContract(state=None,
            abi=abi_json,
            contract_address=address)

    def __getattr__(self, name):
        try:
            getattr(self.contract, name)
        except:
            raise

        def method(*args, **kwargs):
            cd = getattr(self.contract, name)(*args, **kwargs).calldata
            selector = get_selector_from_name(name)
            tx = InvokeFunction(
                contract_address=self.contract.contract_address,
                entry_point_selector=selector,
                calldata=cd,
                signature=[],
            )
            return FuncInvocation(tx)
        return method


class ProxyFuncInvocation:
    def __init__(self, contract: Any, sender: int, to: int, selector: int, calldata: list[int]) -> None:
        self.contract = contract
        self.sender = sender
        self.to = to
        self.selector = selector
        self.cd = calldata

    async def call(self) -> Union[Union[str, int], list[Union[str, int]]]:
        hash = pedersen_hash(self.sender, self.to)
        hash = pedersen_hash(hash, self.selector)
        cd_hash = 0
        if len(self.cd) == 1:
            cd_hash = self.cd[0]
        else:
            cd_hash = pedersen_hash(self.cd[len(self.cd) - 1], self.cd[len(self.cd) - 2])
            for i in range(len(self.cd) - 2, 0, -1):
                cd_hash = pedersen_hash(cd_hash, self.cd[i])
        hash = pedersen_hash(hash, cd_hash)
        nonce = await self.contract.contract.get_nonce().call()
        hash = pedersen_hash(hash, int(nonce))
        # print(f"Nonce: {nonce}, Hash: {hash}")
        signature = sign(msg_hash=hash, priv_key=self.contract.private_key)
        tx = InvokeFunction(
            contract_address=self.contract.address,
            entry_point_selector=get_selector_from_name("execute"),
            calldata=[self.to, self.selector, len(self.cd)] + self.cd,
            signature=list(signature),
        )
        return await FuncInvocation(tx).call()

    #async def invoke(self):
    #    return await FuncInvocation.invoke(self)


class AccountProxy:
    def __init__(self, abi_json: list[Any], address: str, proxy_abi: list[Any], proxy_address: str, private_key: int):
        self.private_key = private_key

        self.contract = ContractWrapper(abi_json, address)
        self.address = int(address, 16)

        self.target = StarknetContract(state=None,
            abi=proxy_abi,
            contract_address=proxy_address)

    def __getattr__(self, name):
        try:
            getattr(self.target, name)
        except:
            raise
        def method(*args, **kwargs):
            cd = getattr(self.target, name)(*args, **kwargs).calldata
            selector = get_selector_from_name(name)
            return ProxyFuncInvocation(self, self.address, self.target.contract_address, selector, cd)
        return method
