import json

def make_func(name, inputs, outputs, mutability):
    # For now, pass all hints, and I'll manually drop those that aren't needed.
    header = f"""
@{mutability}
func {name[0:-1]}{{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, bitwise_ptr: BitwiseBuiltin*, range_check_ptr
    }} ({', '.join([f"{inp['name']}: {inp['type']}" for inp in inputs])}) -> ({', '.join([f"{outp['name']}: {outp['type']}" for outp in outputs])}):"""
    # There are outputs: store them.
    if len(outputs) > 0:
        return header + f"""
    let ({', '.join([outp['name'] for outp in outputs])}) = {name}({', '.join([inp['name'] for inp in inputs])})
    return ({', '.join([outp['name'] for outp in outputs])})
end"""
    else:
        return header + f"""
    {name}({', '.join([inp['name'] for inp in inputs])})
    return ()
end"""


def generate(input_contract, output_path):
    abi_path = f"artifacts/abis/{input_contract}.json"
    abi = json.load(open(abi_path, "r"))

    codeparts = []

    imports = []

    structs = []
    for part in abi:
        if part["type"] == "struct" and part["name"] != 'Uint256':
            structs.append(part["name"])

        if part["type"] != "function":
            continue
        if "stateMutability" not in part:
            codeparts.append(make_func(part["name"], part["inputs"], part["outputs"], "external"))
        else:
            codeparts.append(make_func(part["name"], part["inputs"], part["outputs"], part["stateMutability"]))
        imports.append(part["name"])

    with open(output_path, "w") as f:

        f.write("""
%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin, SignatureBuiltin, BitwiseBuiltin
""")
        f.write(f"from contracts.{input_contract} import (\n\t" + ',\n\t'.join(imports) + '\n)\n')

        f.write("from contracts.types import (\n\t" + ',\n\t'.join(structs) + '\n)\n')

        for part in codeparts:
            f.write(part)
            f.write("\n")
    print("Wrote to ", output_path)
