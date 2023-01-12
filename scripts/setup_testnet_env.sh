# NB: for now, run the starknet devnet node manually using
# starknet-devnet --dump-path devnetstate --accounts 0 --lite-mode --dump-on exit
# then 
# starknet-devnet --dump-path devnetstate --accounts 0 --lite-mode --dump-on exit --load-path devnetstate

export STARKNET_WALLET=starkware.starknet.wallets.open_zeppelin.OpenZeppelinAccount
export STARKNET_NETWORK_ID="goerli"
export STARKNET_NETWORK="alpha-goerli"
export WALLET_ADDRESS="0x22030445da671e4f5bdab7802a061ca0c55754d9703c5390266fd8b814de880"


#####

# NB: for now, run the starknet devnet node manually using
# starknet-devnet --dump-path devnetstate --accounts 0 --lite-mode --dump-on exit
# then 
# starknet-devnet --dump-path devnetstate --accounts 0 --lite-mode --dump-on exit --load-path devnetstate

export STARKNET_NETWORK_ID="goerli-2"
export STARKNET_NETWORK="alpha-goerli2"
export STARKNET_WALLET=starkware.starknet.wallets.open_zeppelin.OpenZeppelinAccount
export GATEWAY_URL="https://alpha4-2.starknet.io"
export FEEDER_GATEWAY_URL="https://alpha4-2.starknet.io"
export TOKEN='0'

export ACCOUNT="testnet_2_deployer_1"
# info stored in ~/.starknet_accounts/starknet_open_zeppelin_accounts.json
comm=$(starknet deploy_account --account $ACCOUNT)
comm=$(echo "$comm" | grep 'Contract address' | awk '{gsub("Contract address: ", "",$0); print $0}')
export WALLET_ADDRESS=$comm

## Already deployed
export ACCOUNT="testnet_2_deployer_1"
export WALLET_ADDRESS="0x0624aa94dd5121e18cfcef94f724706caa4dda69cb621c8b7a9b57fc2efc94ae"


starknet new_account
Account address: 0x033d820bae2318e0e0f93e6d68e36de7ba70de850a6c367eca64f3a9aa74e4f4
Public key: 0x059dc5e6ebbb737014bcf7a5e4abad254e158b88d201ef90c81d5337c3db895b
Move the appropriate amount of funds to the account, and then deploy the account
by invoking the 'starknet deploy_account' command.

NOTE: This is a modified version of the OpenZeppelin account contract. The signature is computed
differently.

export STARKNET_NETWORK_ID="goerli-2"
export STARKNET_WALLET=starkware.starknet.wallets.open_zeppelin.OpenZeppelinAccount
export STARKNET_NETWORK="alpha-goerli2"
export WALLET_ADDRESS="0x33d820bae2318e0e0f93e6d68e36de7ba70de850a6c367eca64f3a9aa74e4f4"
source goerli-2.test_node.txt