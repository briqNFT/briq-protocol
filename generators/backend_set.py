import json

from .backend import get_cairo, get_header, onlyAdminAndFirst

def generate():
    data = json.load(open("artifacts/set_backend.json", "r"))

    code, interface = get_cairo(data, {}, onlyAdminAndFirst)
    header = get_header()

    output = f"""
{header}
{interface}
{code}
    """

    return output