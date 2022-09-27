# NB: for now, run the starknet devnet node manually using
# starknet-devnet --dump-path devnetstate --accounts 0 --lite-mode --dump-on exit
# then 
# starknet-devnet --dump-path devnetstate --accounts 0 --lite-mode --dump-on exit --load-path devnetstate

export STARKNET_NETWORK_ID="goerli"
export STARKNET_NETWORK="alpha-goerli"
export STARKNET_WALLET=starkware.starknet.wallets.open_zeppelin.OpenZeppelinAccount

export ACCOUNT="test_deployer_0_10"
# info stored in ~/.starknet_accounts/starknet_open_zeppelin_accounts.json
comm=$(starknet deploy_account --account $ACCOUNT)
comm=$(echo "$comm" | grep 'Contract address' | awk '{gsub("Contract address: ", "",$0); print $0}')
export WALLET_ADDRESS=$comm

## Already deployed
export ACCOUNT="test_deployer_0_10"
export WALLET_ADDRESS="0x22030445da671e4f5bdab7802a061ca0c55754d9703c5390266fd8b814de880"
