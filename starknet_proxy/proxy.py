from flask import Flask
import subprocess

app = Flask(__name__)

@app.route("/")
async def hello_world():
    proc = subprocess.run(args=["starknet", "invoke", "--address", "toto", "--abi", "briq_abi.json", "--function", "func", "--inputs", ""])
    return "Ret: " + str(proc.returncode) + " " + str(proc.stdout) + " " + str(proc.stderr)