PUB_KEY="2432998744514563413599560991658320623976117616773403151959035807201574477109"
starknet deploy --contract account.json --inputs $PUB_KEY --network alpha
ADDR="0x06dcf2ac3802c797c6e57e3aa1659307f47a8a9562e7c18ed6c11838b8b7d79d"
starknet invoke --function initialize --abi account_abi.json --inputs $ADDR --network alpha --address $ADDR
