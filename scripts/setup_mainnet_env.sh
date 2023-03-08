export STARKNET_WALLET=starkware.starknet.wallets.open_zeppelin.OpenZeppelinAccount
export STARKNET_NETWORK_ID="mainnet"
export STARKNET_NETWORK="alpha-mainnet"
export WALLET_ADDRESS="0x75341b8090a4257f22dafffe3a4cb882006bd26302720d6a80a1fde154a3430"
PROMPT='%F{blue}MAINNET%f %1~ %# '








# NB: for now, run the starknet devnet node manually using
# starknet-devnet --dump-path devnetstate --accounts 0 --lite-mode --dump-on exit
# then 
# starknet-devnet --dump-path devnetstate --accounts 0 --lite-mode --dump-on exit --load-path devnetstate

export STARKNET_NETWORK_ID="mainnet"
export STARKNET_NETWORK="alpha-mainnet"
export STARKNET_WALLET=starkware.starknet.wallets.open_zeppelin.OpenZeppelinAccount

export ACCOUNT="mainnet_deployer_1"
# info stored in ~/.starknet_accounts/starknet_open_zeppelin_accounts.json
comm=$(starknet deploy_account --account $ACCOUNT)
comm=$(echo "$comm" | grep 'Contract address' | awk '{gsub("Contract address: ", "",$0); print $0}')
export WALLET_ADDRESS=$comm

## Already deployed
export ACCOUNT="mainnet_deployer_1"
export WALLET_ADDRESS="0x75341b8090a4257f22dafffe3a4cb882006bd26302720d6a80a1fde154a3430"
export TOKEN="0x269144bcf78891dbf22d757cbbe8e77c6a2a8868c379dc7d82fb94a04aa4b65"
