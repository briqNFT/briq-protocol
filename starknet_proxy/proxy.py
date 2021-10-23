import os
import subprocess
from flask import Flask
from flask import request
from flask_cors import CORS

app = Flask(__name__)
CORS(app)

ADDRESS = os.environ.get("ADDRESS") or "0x032558a3801160d4fec8db90a143e225534a3a0de2fb791b370527b76bf18d16"
SET_ADDRESS = os.environ.get("SET_ADDRESS") or "0x032558a3801160d4fec8db90a143e225534a3a0de2fb791b370527b76bf18d16"
GATEWAY_URL = os.environ.get("GATEWAY_URL") or None
FEEDER_GATEWAY_URL = os.environ.get("FEEDER_GATEWAY_URL") or None

default_args = []
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

def cli_call(command):
    proc = subprocess.run(args=command, capture_output=True)
    val = None
    try:
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

@app.route("/init")
async def init():
    cli_call(get_command(True, "initialize", [], SET_ADDRESS))
    return "ok"

@app.route("/call_func/<name>", methods=["GET", "POST"])
async def call_func(name):
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

@app.route("/get_bricks/<owner>", methods=["GET", "POST"])
async def get_bricks(owner):
    comm = get_command(False, "balance_of", [str(owner)])
    print(" ".join(comm))
    try:
       balance = int(cli_call(comm)["value"])
    except Exception as e:
        print(e)
        return {
            "error": "Could not get the balance", "code": 500
        }, 500
    runs = balance // 20 + 1
    print(f"runs: {runs}")
    ret = []
    for i in range(0, runs):
        comm = get_command(False, "tokens_at_index", [str(owner), str(i)])
        print(" ".join(comm))
        try:
            bricks = cli_call(comm)["value"].split(" ")
        except Exception:
            return {
                "error": "Error fetching brick data", "code": 500
            }, 500
        for j in range(0, min(balance - i*20, 20)):
            # First token ID, then material, then part-of-set.
            ret.append((hex(int(bricks[j*3])), int(bricks[j*3+1]), int(bricks[j*3+2])))
    return {
        "code": 200,
        "value": ret
    }

@app.route("/store_set", methods=["POST"])
async def store_set():
    data = request.get_json()["data"]
    bricks = ["0x123", "0x124", "0x125"]
    comm = get_command(True, "mint", ["0x11", str(len(bricks))] + bricks, SET_ADDRESS)
    print(" ".join(comm))
    print(cli_call(comm))
    return "ok", 200
