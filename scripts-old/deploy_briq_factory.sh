source "$STARKNET_NETWORK_ID.test_node.txt"

starknet_declare () {
    addr="$(starknet declare --contract $1 --nonce $nonce --max_fee 993215999380800)"
    echo $addr
    comm=$(echo "$addr" | grep 'Contract class hash' | awk '{gsub("Contract class hash: ", "",$0); print $0}')
    printf -v $2 $comm
    echo "$2=$comm"
    echo "$2=$comm" >> "$STARKNET_NETWORK_ID.test_node.txt"
    ((nonce=$nonce+1))
}

deploy_proxy() {
    addr="$(starknet deploy --class_hash $proxy_hash --inputs $WALLET_ADDRESS $1 --nonce $nonce --max_fee 2220277007180367)"
    echo $addr
    comm=$(echo "$addr" | grep "Contract address: " | awk '{gsub("Contract address: ", "",$0); print $0}')
    printf -v $2 $comm
    echo "$2=$comm"
    echo "$2=$comm" >> "$STARKNET_NETWORK_ID.test_node.txt"
    ((nonce=$nonce+1))
}

invoke () {
    tx=$(starknet invoke --address $1 --abi artifacts/abis/$2.json --function $3 --inputs $4 $5 $6 $7  --nonce $nonce --max_fee 12618293576158800)
    export tx_hash=$(echo $tx | grep "Transaction hash:" | awk '{gsub("Transaction hash: ", "",$0); print $0}')
    echo "$2 $3"
    echo "starknet get_transaction --hash $tx_hash"
    ((nonce=$nonce+1))
}


call () {
    tx=$(starknet call --address $1 --abi artifacts/abis/$2.json --function $3 --inputs $4 $5 $6 $7)
    echo $tx
}

nonce=$(starknet get_nonce --contract_address $WALLET_ADDRESS)

starknet_declare artifacts/briq.json briq_hash
starknet_declare artifacts/briq_factory.json briq_factory_hash

deploy_proxy $briq_factory_hash briq_factory_addr

# Start at 300000
invoke $briq_factory_addr briq_factory initialise 300000000000000000000000 0 0x049d36570d4e46f48e99674bd3fcc84644ddd6b96f7c741b1562b82f9e004dc7
invoke $briq_factory_addr briq_factory setBriqAddress_ $briq_addr

call $briq_factory_addr briq_factory get_price 30

invoke $briq_addr box_nft upgradeImplementation_ $briq_hash
invoke $briq_addr briq setFactoryAddress_ $briq_factory_addr

# Upgrade
nonce=$(starknet get_nonce --contract_address $WALLET_ADDRESS)
echo $nonce

starknet_declare artifacts/briq_factory.json briq_factory_hash
invoke $briq_factory_addr briq_factory upgradeImplementation_ $briq_factory_hash
