import json
from typing import Any, Union

from starkware.starknet.testing.contract import StarknetContract
from starkware.starknet.compiler.compile import get_selector_from_name
from starkware.starknet.services.api.gateway.transaction import Deploy, InvokeFunction
from services.external_api.base_client import RetryConfig
from starkware.starknet.services.api.feeder_gateway.feeder_gateway_client import FeederGatewayClient
from starkware.starknet.services.api.gateway.gateway_client import GatewayClient

from starkware.cairo.lang.tracer.tracer_data import field_element_repr
from starkware.starknet.definitions import fields

retry_config = RetryConfig(n_retries=1)
client = GatewayClient(url="https://alpha3.starknet.io/gateway/", retry_config=retry_config)
feeder_client = FeederGatewayClient(url="https://alpha3.starknet.io/feeder_gateway/", retry_config=retry_config)

def felt_formatter(hex_felt: str) -> Union[str, int]:
    #return field_element_repr(val=int(hex_felt, 16), prime=fields.FeltField.upper_bound)
    try:
        return int(hex_felt, 16)
    except:
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
