# Run katana

# Configure for starkli
export STARKNET_RPC="http://localhost:5050/"

# password is katana
export STARKNET_KEYSTORE="scripts/katana_signer.json"
export KEYSTORE_PWD="katana"

export STARKNET_ACCOUNT="scripts/katana_account.json"
export ACCOUNT_ADDRESS=$(jq .deployment.address $STARKNET_ACCOUNT -r)

export TREASURY_ADDRESS="0x33c627a3e5213790e246a917770ce23d7e562baa5b4d2917c23b1be6d91961c"

# https://github.com/dojoengine/dojo/blob/main/crates/katana/core/src/constants.rs
# katana predeployed fee_token_address (uses transferFrom..)
export FEE_TOKEN_ADDR="0x049d36570d4e46f48e99674bd3fcc84644ddd6b96f7c741b1562b82f9e004dc7"
