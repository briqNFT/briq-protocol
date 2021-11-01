import os
import subprocess
from flask import Flask
from flask import request, redirect, url_for
from flask_cors import CORS

app = Flask(__name__)
CORS(app, origins=["https://sltech.company", "https://sltech.company"])

ADDRESS = os.environ.get("ADDRESS") or "0x032558a3801160d4fec8db90a143e225534a3a0de2fb791b370527b76bf18d16"
SET_ADDRESS = os.environ.get("SET_ADDRESS") or "0x032558a3801160d4fec8db90a143e225534a3a0de2fb791b370527b76bf18d16"
GATEWAY_URL = os.environ.get("GATEWAY_URL") or None
FEEDER_GATEWAY_URL = os.environ.get("FEEDER_GATEWAY_URL") or None

default_args = ["--network", "alpha"]
if (GATEWAY_URL is not None):
    default_args = [
        "--gateway_url", GATEWAY_URL,
        "--feeder_gateway_url", FEEDER_GATEWAY_URL
    ]

print(ADDRESS)
print(SET_ADDRESS)

def get_command(invoke, funcname, inputs, addr = ADDRESS):
    return ["starknet", ("invoke" if invoke else "call"),
            "--address", addr,
            "--abi", "briq_abi.json" if addr == ADDRESS else "set_abi.json",
            "--function", funcname] + (["--inputs"] + inputs if len(inputs) else []) + default_args

def parse_cli_answer(proc, full_res=False):
    val = None
    try:
        if full_res:
            val  = proc.stdout.decode('utf-8')
        else:
            val = proc.stdout.decode('utf-8').split("\n")[0]
    except Exception:
        pass
    if proc.returncode == 0:
        return {
            "code": proc.returncode,
            "value": val
        }
    return {
        "code": proc.returncode,
        "stdout": str(proc.stdout.decode('utf-8')),
        "stderr": str(proc.stderr.decode('utf-8'))
    }


def parse_cli_answer_async(proc, full_res=False):
    val = None
    try:
        if full_res:
            val  = proc.stdout.read().decode('utf-8')
        else:
            val = proc.stdout.read().decode('utf-8').split("\n")[0]
    except Exception:
        pass
    if proc.returncode == 0:
        return {
            "code": proc.returncode,
            "value": val
        }
    return {
        "code": proc.returncode,
        "stdout": str(proc.stdout.read().decode('utf-8')),
        "stderr": str(proc.stderr.read().decode('utf-8'))
    }

def cli_call(command, full_res=False):
    proc = subprocess.run(args=command, capture_output=True, timeout=60)
    return parse_cli_answer(proc, full_res)

@app.route("/init")
def init():
    cli_call(get_command(True, "initialize", [], SET_ADDRESS))
    cli_call(get_command(True, "set_briq_contract", [ADDRESS], SET_ADDRESS))
    return "ok"

@app.route("/set_contract")
def set_contract():
    cli_call(get_command(True, "set_briq_contract", [ADDRESS], SET_ADDRESS))
    return "ok"

@app.route("/health")
def health():
    return "ok"

@app.route("/call_func/<name>", methods=["GET", "POST"])
def call_func(name):
    try:
        inputs = dispatch_inputs(name, request.get_json()["inputs"])
    except Exception as e:
        return { "error": str(e), "code": 500 }, 500
    print(" ".join(["starknet", get_call_invoke(name),
            "--address", ADDRESS,
            "--abi", "briq_abi.json",
            "--function", name,
            "--inputs"] + inputs + default_args)),
    proc = subprocess.run(args=["starknet", get_call_invoke(name),
            "--address", ADDRESS,
            "--abi", "briq_abi.json",
            "--function", name,
            "--inputs"] + inputs + default_args,
        capture_output=True)
    val = None
    try:
        val = proc.stdout.decode('utf-8').split("\n")[0]
    except Exception:
        pass
    if val is not None:
        return {
            "code": proc.returncode,
            "value": val
        }
    return {
        "code": proc.returncode,
        "stdout": str(proc.stdout.decode('utf-8'))
    }

def dispatch_inputs(name, inputs):
    if name == "balance_of":
        return [str(inputs["owner"])]
    if name == "token_at_index":
        return [str(inputs["owner"]), str(inputs["index"])]
    if name == "owner_of":
        return [str(inputs["token_id"])]
    if name == "mint":
        return [str(inputs["owner"]), str(inputs["token_id"]), str(inputs["material"])]
    if name == "transfer_from":
        return [str(inputs["sender"]), str(inputs["recipient"]), str(inputs["token_id"])]

def get_call_invoke(name):
    if name == "mint" or name == "transfer_from":
        return "invoke"
    return "call"

@app.route("/mint_bricks/<owner>", methods=["GET", "POST"])
def mint_bricks(owner):
    req = request.get_json()
    comm = get_command(True, "mint_multiple", [str(owner), str(req["material"]), str(req["token_start"]), str(req["nb"])])
    print(" ".join(comm))
    res = cli_call(comm, full_res=True)["value"].split("\n")[2]
    print(res)

    return {
        "code": 200
    }, 200

@app.route("/get_bricks/<owner>", methods=["GET", "POST"])
def get_bricks(owner):
    comm = get_command(False, "tokens_at_index", [str(owner), "0"])
    print(" ".join(comm))
    proc = subprocess.Popen(args=comm, stderr=subprocess.PIPE, stdout=subprocess.PIPE)
    comm = get_command(False, "balance_of", [str(owner)])
    print(" ".join(comm))
    try:
       balance = int(cli_call(comm)["value"])
    except Exception as e:
        print(e)
        return {
            "error": "Could not get the balance", "code": 500
        }, 500
    items_returned = 100
    runs = balance // items_returned + 1
    ret = []
    for i in range(1, runs):
        comm = get_command(False, "tokens_at_index", [str(owner), str(i)])
        print(" ".join(comm))
        try:
            bricks = cli_call(comm)["value"].split(" ")
        except Exception:
            return {
                "error": "Error fetching brick data", "code": 500
            }, 500
        for j in range(0, min(balance - i*items_returned, items_returned)):
            # First token ID, then material, then part-of-set.
            ret.append((hex(int(bricks[j*3])), int(bricks[j*3+1]), int(bricks[j*3+2])))
    proc.wait(timeout=60)
    bricks = parse_cli_answer_async(proc)["value"].split(" ")
    for j in range(0, min(balance, items_returned)):
        # First token ID, then material, then part-of-set.
        ret.append((hex(int(bricks[j*3])), int(bricks[j*3+1]), int(bricks[j*3+2])))
    return {
        "code": 200,
        "value": ret
    }

import json
import random
import time
import os

random.seed()

@app.route("/store_set", methods=["POST"])
def store_set():
    req = request.get_json()
    data = req["data"]
    bricks = [str(x) for x  in req["used_cells"]]
    
    token_id = int(time.time()) + random.randint(0, 10000000)
    
    comm = get_command(True, "mint", [req["owner"], str(token_id), str(len(bricks))] + bricks, SET_ADDRESS)
    #comm = get_command(True, "mint", [str(len(bricks)+1), "0x11"] + bricks, SET_ADDRESS)
    print(" ".join(comm))
    res = cli_call(comm, full_res=True)["value"].split("\n")[2]
    print(res)

    try:
        os.mkdir("temp/")
    except:
        pass
    open(f"temp/{token_id}.json", "w").write(json.dumps(data))

    return {
        "code": 200,
        "value": token_id
    }, 200


@app.route("/store_get/<token_id>", methods=["POST"])
def store_get(token_id):
    comm = get_command(False, "owner_of", [str(token_id)], SET_ADDRESS)
    print(" ".join(comm))
    owner = int(cli_call(comm)['value'])
    if owner == 0:
        return {
            "code": 500,
            "error": "doesn't exist"
        }, 500

    try:
        data = json.loads(open(f"temp/{token_id}.json", "r").read())
        print(data)
    except Exception as e:
        print(e)
        return {
            "code": 500,
            "error": "File not found"
        }, 500

    return {
        "code": 200,
        "owner": owner,
        "token_id": token_id,
        "data": data
    }, 200

@app.route("/store_list", methods=["GET", "POST"])
def store_list():
    return {
        "code": 200,
        "sets": [x for x in os.listdir("temp/") if x.endswith(".json")]
    }, 200
