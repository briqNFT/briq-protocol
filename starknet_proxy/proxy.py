from flask import Flask
from flask import request
import subprocess

app = Flask(__name__)

ADDRESS = "0x032558a3801160d4fec8db90a143e225534a3a0de2fb791b370527b76bf18d16"

@app.route("/call_func/<name>", methods=["GET", "POST"])
async def call_func(name):
    try:
        inputs = dispatch_inputs(name, request.get_json()["inputs"])
    except Exception as e:
        return "Error: " + str(e), 500
    proc = subprocess.run(args=["starknet", "call", "--address", ADDRESS, "--abi", "briq_abi.json", "--function", name, "--inputs", inputs],
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
        return str(inputs["owner"])
