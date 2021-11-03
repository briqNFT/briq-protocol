from fastapi import FastAPI, Request, HTTPException
from fastapi.responses import Response, RedirectResponse
from fastapi.middleware.cors import CORSMiddleware

import requests

app = FastAPI()

app.add_middleware(
    CORSMiddleware,
    allow_origins=[
        "http://localhost:3000",
        "https://sltech.company",
        "http://www.sltech.company",
    ],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

from .storage.storage import get_storage
from .contract import ContractWrapper

import os

ADDRESS = os.environ.get("ADDRESS") or "0x075157ee904c59f9b4f5a2f284284fed3c05e0cc6446fd6578e753554a7a638f"
SET_ADDRESS = os.environ.get("SET_ADDRESS") or "0x002f988869e8e5466cea7cbb52dd3b9e45137eb762afa4f5ae69de1fb55679f7"
GATEWAY_URL = os.environ.get("GATEWAY_URL") or "https://alpha3.starknet.io/gateway/"
FEEDER_GATEWAY_URL = os.environ.get("FEEDER_GATEWAY_URL") or "https://alpha3.starknet.io/feeder_gateway/"

import json
briq_contract = ContractWrapper(abi_json=json.load(open("briq_abi.json", "r")), address=ADDRESS)
set_contract = ContractWrapper(abi_json=json.load(open("set_abi.json", "r")), address=SET_ADDRESS)

from .storage.storage import get_storage
storage_client = get_storage()
print(storage_client)

@app.post("/init")
@app.get("/init")
def init():
    set_contract.initialize().invoke()
    set_contract.set_briq_contract(ADDRESS).invoke()
    return "ok"

@app.post("/set_contract")
@app.get("/set_contract")
def set_contract():
    set_contract.set_briq_contract(ADDRESS).invoke()
    return "ok"

@app.get("/health")
def health():
    return "ok"

@app.post("/get_bricks/{owner}")
@app.get("/get_bricks/{owner}")
async def get_bricks(owner: int):
    tokens = briq_contract.tokens_at_index(owner=owner, index=0).call()
    balance = await briq_contract.balance_of(owner=owner).call()
    assert isinstance(balance, int)

    items_returned = 100
    runs = balance // items_returned + 1
    ret = []
    for i in range(1, runs):
        ret += await briq_contract.tokens_at_index(owner=owner, index=i).call()
    ret += await tokens
    parsed_ret = []
    for i in range(min(balance, len(ret)//3)):
        parsed_ret.append((hex(int(ret[i*3])), int(ret[i*3+1]), int(ret[i*3+2])))

    return {
        "code": 200,
        "value": parsed_ret
    }

@app.post("/store_get/{token_id}")
@app.get("/store_get/{token_id}")
async def store_get(token_id: int):
    owner = await set_contract.owner_of(token_id).call()
    if owner == 0:
        HTTPException(status_code=500, detail="Set does not exist")

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

# Proxy other get/post requests
@app.post("/{path_name:path}")
async def catch_all_post(request: Request, path_name: str):
    data = await request.json()
    t_resp = requests.post(
        url=f'http://localhost:5001/{path_name}',
        data=data)
    return Response(content=t_resp.text, status_code=t_resp.status_code, media_type=t_resp.headers['content-type'])

@app.get("/{path_name:path}")
async def catch_all_get(request: Request, path_name: str):
    t_resp = requests.get(url=f'http://localhost:5001/{path_name}')
    return Response(content=t_resp.text, status_code=t_resp.status_code, media_type=t_resp.headers['content-type'])
