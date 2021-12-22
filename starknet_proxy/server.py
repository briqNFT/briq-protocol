from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware

app = FastAPI()

app.add_middleware(
    CORSMiddleware,
    allow_origins=[
        "http://localhost:3000",
        "https://sltech.company",
        "https://www.sltech.company",
        "https://briq.construction",
        "https://www.briq.construction",
        "https://test.sltech.company",
    ],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

from pydantic import BaseModel
from typing import Dict, Any
from .storage.storage import get_storage
storage_client = get_storage()

@app.get("/health")
def health():
    return "ok"

@app.post("/store_get/{token_id}")
@app.get("/store_get/{token_id}")
async def store_get(token_id: str):
    try:
        data = storage_client.load_json(path=token_id)
    except Exception as e:
        print(e)
        raise HTTPException(status_code=500, detail="File not found")

    return {
        "code": 200,
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

class Set(BaseModel):
    token_id: str
    data: Dict[str, Any]

@app.post("/store_set")
async def store_set(set: Set):
    # TODO: improve on this.
    if storage_client.has_json(path=set.token_id):
        raise HTTPException(status_code=500, detail="Set already exists or existed")
    storage_client.store_json(path=set.token_id, data=set.data)
    return {
        "code": 200,
        "value": set.token_id
    }
