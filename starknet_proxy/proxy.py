import os
import subprocess
from flask import Flask
from flask import request
from flask_cors import CORS

app = Flask(__name__)
CORS(app)

ADDRESS = os.environ.get("ADDRESS") or "0x032558a3801160d4fec8db90a143e225534a3a0de2fb791b370527b76bf18d16"
GATEWAY_URL = os.environ.get("GATEWAY_URL") or None
FEEDER_GATEWAY_URL = os.environ.get("FEEDER_GATEWAY_URL") or None

default_args = []
if (GATEWAY_URL is not None):
    default_args = [
        "--gateway_url", GATEWAY_URL,
        "--feeder_gateway_url", FEEDER_GATEWAY_URL
    ]

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

def get_call_invoke(name):
    if name == "mint":
        return "invoke"
    return "call"