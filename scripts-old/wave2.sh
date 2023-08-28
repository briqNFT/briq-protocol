
starknet_declare () {
    addr="$(starknet declare --contract $1 --account $ACCOUNT --nonce $nonce --max_fee 993215999380800 --token $TOKEN)"
    echo $addr
    comm=$(echo "$addr" | grep 'Contract class hash' | awk '{gsub("Contract class hash: ", "",$0); print $0}')
    printf -v $2 $comm
    echo "$2=$comm"
    echo "$2=$comm" >> "$STARKNET_NETWORK_ID.test_node.txt"
    ((nonce=$nonce+1))
}

invoke () {
    tx=$(starknet invoke --address $1 --abi artifacts/abis/$2.json --function $3 --inputs $4 $5 $6 $7 --account $ACCOUNT  --nonce $nonce --max_fee 12618293576158800)
    export tx_hash=$(echo $tx | grep "Transaction hash:" | awk '{gsub("Transaction hash: ", "",$0); print $0}')
    echo "$2 $3"
    echo "starknet get_transaction --hash $tx_hash"
    ((nonce=$nonce+1))
}


call () {
    tx=$(starknet call --address $1 --abi artifacts/abis/$2.json --function $3 --inputs $4 $5 $6 $7 --account $ACCOUNT)
    echo $tx
}


nonce=$(starknet get_nonce --contract_address $WALLET_ADDRESS)
starknet_declare artifacts/box_nft_wave2.json box_nft_wave2_hash
starknet_declare artifacts/shape_store_wave2.json shape_store_wave2

echo $box_nft_wave2_hash

call $box_addr box_nft getImplementation_

invoke $box_addr box_nft upgradeImplementation_ $box_nft_wave2_hash

invoke $box_addr box_nft mint_ $auction_addr 4 150
invoke $box_addr box_nft mint_ $auction_addr 5 50
invoke $box_addr box_nft mint_ $auction_addr 6 5

call $box_addr box_nft get_box_data 4


nonce=$(starknet get_nonce --contract_address $WALLET_ADDRESS)
starknet_declare artifacts/box_nft_wave3.json box_nft_wave3_hash

echo $box_nft_wave3_hash

call $box_addr box_nft getImplementation_

invoke $box_addr box_nft upgradeImplementation_ $box_nft_wave3_hash

call $auction_addr auction get_auction_data

invoke $box_addr box_nft mint_ $auction_addr 7 150
invoke $box_addr box_nft mint_ $auction_addr 8 50
invoke $box_addr box_nft mint_ $auction_addr 9 5

call $box_addr box_nft get_box_data 4

starknet_declare artifacts/shape_store_wave3.json shape_store_wave3
