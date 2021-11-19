from dataclasses import dataclass

from marshmallow.fields import Str
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware

import requests

app = FastAPI()

app.add_middleware(
    CORSMiddleware,
    allow_origins=[
        "http://localhost:3000",
        "https://sltech.company",
        "https://www.sltech.company",
        "https://briq.construction",
        "https://www.briq.construction",
    ],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

from .storage.storage import get_storage
from .contract import set_gateway, ContractWrapper

import os

ADDRESS = os.environ.get("ADDRESS") or "0x05fd6b2390ebb20145309db6e58ca4e696dfac3b3525750ad7e8f31ef125506a"
SET_ADDRESS = os.environ.get("SET_ADDRESS") or "0x07309cc705f05e9ae6e2ab4ac447fa8a783e621d21a13793187773cd93ac9438"
GATEWAY_URL = os.environ.get("GATEWAY_URL") or "https://alpha4.starknet.io/"
set_gateway(GATEWAY_URL)

print(f"Briq contract: {ADDRESS}")
print(f"Set contract: {SET_ADDRESS}")

import json
briq_contract = ContractWrapper(abi_json=json.load(open("briq_abi.json", "r")), address=ADDRESS)
set_contract = ContractWrapper(abi_json=json.load(open("set_abi.json", "r")), address=SET_ADDRESS)

from .storage.storage import get_storage
storage_client = get_storage()
print(storage_client)


@app.post("/init")
@app.get("/init")
async def init():
    await set_contract.initialize().invoke()
    await set_contract.set_briq_contract(int(ADDRESS, 16)).invoke()
    return "ok"


@app.post("/set_contract")
@app.get("/set_contract")
async def init_set_contract():
    await set_contract.set_briq_contract(int(ADDRESS, 16)).invoke()
    return "ok"


@app.get("/health")
def health():
    return "ok"


@app.get("/contract_addresses")
async def contract_addresses():
    return {
        "briq": ADDRESS,
        "set": SET_ADDRESS,
    }


@app.get("/balance_of/{owner}")
async def get_briq_balance_of(owner: int):
    return await briq_contract.balance_of(owner).call()

@app.get("/owner_of/{token_id}")
async def get_briq_owner_of(token_id: int):
    return await briq_contract.owner_of(token_id).call()

@app.post("/get_bricks/{owner}")
@app.get("/get_bricks/{owner}")
async def get_bricks(owner: int):
    tokens = await briq_contract.get_all_tokens_for_owner(owner=owner).call()
    print(tokens)
    parsed_ret = []
    for i in range(0, tokens[0]//3):
        parsed_ret.append((hex(int(tokens[1+i*3])), int(tokens[1+i*3+1]), int(tokens[1+i*3+2])))

    return {
        "code": 200,
        "value": parsed_ret
    }

@app.post("/store_get/{token_id}")
@app.get("/store_get/{token_id}")
async def store_get(token_id: int):
    owner = await set_contract.owner_of(token_id).call()
    if owner == 0:
        raise HTTPException(status_code=500, detail="Set does not exist")

    try:
        data = storage_client.load_json(path=str(token_id))
    except Exception as e:
        print(e)
        raise HTTPException(status_code=500, detail="File not found")

    return {
        "code": 200,
        "owner": owner,
        "token_id": token_id,
        "data": data
    }

@app.post("/store_list")
@app.get("/store_list")
def store_list():
    return {
        "code": 200,
        "sets": storage_client.list_json()
    }


from pydantic import BaseModel

from typing import Dict, Any
class Set(BaseModel):
    owner: int
    data: Dict[str, Any]
    used_cells: list[int]

import time
import random

@app.post("/store_set")
async def store_set(set: Set):
    token_id = int(time.time()) + random.randint(0, 10000000)
    transaction = await set_contract.mint(owner=set.owner, token_id=token_id, bricks=set.used_cells).invoke()
    print(transaction)
    storage_client.store_json(path=str(token_id), data=set.data)
    #open(f"temp/{token_id}.json", "w").write(json.dumps(data))

    return {
        "code": 200,
        "value": token_id
    }

class DeletionRequest(BaseModel):
    token_id: int
    bricks: list[int]

@app.post("/store_delete")
async def store_delete(dr: DeletionRequest):
    print(await set_contract.disassemble(user=17, token_id=dr.token_id, bricks=[x for x in dr.bricks]).invoke())
    return {
        "code": 200
    }

class MintRequest(BaseModel):
    material: int
    token_start: int
    nb: int

@app.post("/mint_bricks/{owner}")
async def mint_bricks(owner, mr: MintRequest):
    print(await briq_contract.mint_multiple(owner=int(owner), material=mr.material, token_start=mr.token_start, nb=mr.nb).invoke())
    return {
        "code": 200
    }
