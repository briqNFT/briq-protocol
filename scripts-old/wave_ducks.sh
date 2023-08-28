
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

# Hashes
source "$STARKNET_NETWORK_ID.test_node.txt"

nonce=$(starknet get_nonce --contract_address $WALLET_ADDRESS)

echo $nonce
echo $WALLET_ADDRESS



# Upgrade booklet contract for minting
starknet_declare artifacts/booklet_nft.json booklet_hash
invoke $booklet_addr box_nft upgradeImplementation_ $booklet_hash

invoke $attributes_registry_addr attributes_registry create_collection_ 3 2 $booklet_addr

# Deploy shape
starknet_declare artifacts/shape_store_ducks.json shape_store_ducks_hash


echo $set_addr
echo $auction_onchain_data_hash

# Deploy auction contract
starknet_declare artifacts/auction_onchain.json auction_onchain_hash
starknet_declare "artifacts/auction_onchain_data_${STARKNET_NETWORK_ID}.json" auction_onchain_data_hash

deploy_proxy $auction_onchain_hash auction_onchain_addr

invoke $auction_onchain_addr auction_onchain setPaymentAddress_ 0x049d36570d4e46f48e99674bd3fcc84644ddd6b96f7c741b1562b82f9e004dc7
invoke $auction_onchain_addr auction_onchain setSetAddress_ $set_addr
invoke $auction_onchain_addr auction_onchain setDataHash_ $auction_onchain_data_hash

call $booklet_addr booklet_nft get_shape_ 0x13000000000000000000000000000000000000000000000003
call $auction_onchain_addr auction_onchain get_auction_data 1


## Second part
# upgrade auction
starknet_declare "artifacts/auction_onchain_data_${STARKNET_NETWORK_ID}.json" auction_onchain_data_hash
invoke $auction_onchain_addr auction_onchain setDataHash_ $auction_onchain_data_hash

invoke $set_addr set_nft setApprovalForAll_ $auction_onchain_addr 1


starknet invoke --address $auction_onchain_addr --abi artifacts/abis/auction_onchain.json --function settle_auctions --nonce $nonce --max_fee 126182935761588000 --inputs 49 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30 32 33 34 35 36 37 38 39 40 41 42 43 44 45 46 47 48 49 50
starknet invoke --address $auction_onchain_addr --abi artifacts/abis/auction_onchain.json --function settle_auctions --nonce $nonce --max_fee 126182935761588000 --inputs 50 51 52 53 54 55 56 57 58 59 60 61 62 63 64 65 66 67 68 69 70 71 72 73 74 75 76 77 78 79 80 81 82 83 84 85 86 87 88 89 90 91 92 93 94 95 96 97 98 99 100
starknet invoke --address $auction_onchain_addr --abi artifacts/abis/auction_onchain.json --function settle_auctions --nonce $nonce --max_fee 126182935761588000 --inputs 50 151 152 153 154 155 156 157 158 159 160 161 162 163 164 165 166 167 168 169 170 171 172 173 174 175 176 177 178 179 180 181 182 183 184 185 186 187 188 189 190 191 192 193 194 195 196 197 198 199 200
starknet invoke --address $auction_onchain_addr --abi artifacts/abis/auction_onchain.json --function settle_auctions --nonce $nonce --max_fee 126182935761588000 --inputs 50 101 102 103 104 105 106 107 108 109 110 111 112 113 114 115 116 117 118 119 120 121 122 123 124 125 126 127 128 129 130 131 132 133 134 135 136 137 138 139 140 141 142 143 144 145 146 147 148 149 150
starknet invoke --address $auction_onchain_addr --abi artifacts/abis/auction_onchain.json --function settle_auctions --nonce $nonce --max_fee 126182935761588000 --inputs 199 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30 32 33 34 35 36 37 38 39 40 41 42 43 44 45 46 47 48 49 50 51 52 53 54 55 56 57 58 59 60 61 62 63 64 65 66 67 68 69 70 71 72 73 74 75 76 77 78 79 80 81 82 83 84 85 86 87 88 89 90 91 92 93 94 95 96 97 98 99 100 101 102 103 104 105 106 107 108 109 110 111 112 113 114 115 116 117 118 119 120 121 122 123 124 125 126 127 128 129 130 131 132 133 134 135 136 137 138 139 140 141 142 143 144 145 146 147 148 149 150 151 152 153 154 155 156 157 158 159 160 161 162 163 164 165 166 167 168 169 170 171 172 173 174 175 176 177 178 179 180 181 182 183 184 185 186 187 188 189 190 191 192 193 194 195 196 197 198 199 200


## Deploying new ducks
starknet_declare artifacts/shape_store_ducks.json shape_store_ducks_hash
