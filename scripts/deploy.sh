# Source one of the setup scripts.

sozo build

sozo migrate --name test-0 --keystore $STARKNET_KEYSTORE --password $KEYSTORE_PWD

export WORLD_ADDRESS=0x50a4b38276c79e4edac9a3deefdc47dd6c2c95ed372ab657594f68053d0a90d
export SETUP_WORLD_ADDR=0x237ad7e9e4522d00b835842d9dcfbfe454b9e7f1cd7baa2506951342328d732
export FACTORY_ADDR=0x7ed7e70521669f6702a8af0f01f19115dece1ca4b71e30d009f46778d29e42b
export BOX_ADDR=0x43fc8996a4945d204d57248ff40ad5505f920ec46068ac53c10e420f902913d
export DUCK_BOOKLET_ADDR=0x2b236bcfe0e481ced6a0e5a5e2da5f464ce1a44dea7e53ab01ba24a78a01c08
export BRIQ_ADDR=0x74a4b893fffb629d84345e3b886f553209a7e15db3ae5a4ef39b9c22ac37a5c
export SET_ADDR=0x1bfffd97b03cfc2d5fb823db38a6a5562be32ac36faa94772317d8cbb71d3b1
export DUCKS_ADDR=0x43ad180f076a4b263bc430d2698096bcba2f4b7e0317159deb4b3698cecb838

echo "\n*************************************"
echo FEE_TOKEN_ADDR=$FEE_TOKEN_ADDR
echo BRIQ_ADDR=$BRIQ_ADDR
echo SET_ADDR=$SET_ADDR
echo FACTORY_ADDR=$FACTORY_ADDR
echo DUCKS_ADDR=$DUCKS_ADDR
echo DUCK_BOOKLET_ADDR=$DUCK_BOOKLET_ADDR
echo BOX_ADDR=$BOX_ADDR
echo "*************************************"

## Setup World config
sozo execute $SETUP_WORLD_ADDR execute --calldata $WORLD_ADDRESS,$TREASURY_ADDRESS,$BRIQ_ADDR,$SET_ADDR,$FACTORY_ADDR --keystore $STARKNET_KEYSTORE --password $KEYSTORE_PWD
#starkli invoke $SETUP_WORLD_ADDR execute $WORLD_ADDRESS $TREASURY_ADDRESS $BRIQ_ADDR $SET_ADDR $FACTORY_ADDR --keystore-password $KEYSTORE_PWD

## Return World config
sozo model get WorldConfig 1 --world $WORLD_ADDRESS
#starkli call $WORLD_ADDRESS entity str:WorldConfig 1 1 0 4 4 251 251 251 251

## Setup briq_factory
sozo execute $BRIQ_FACTORY_ADDR initialize --calldata 0,0,$FEE_TOKEN_ADDR --keystore $STARKNET_KEYSTORE --password $KEYSTORE_PWD
#starkli invoke $BRIQ_FACTORY_ADDR initialize 0 0 $FEE_TOKEN_ADDR --keystore-password $KEYSTORE_PWD

## Return briq_factory config
sozo model get BriqFactoryStore 1 --world $WORLD_ADDRESS

#### Setup authorizations

starkli invoke $SETUP_WORLD_ADDR register_set_contract $WORLD_ADDRESS $SET_ADDR 1 --keystore-password $KEYSTORE_PWD

sozo auth writer ERC1155Balance BriqFactoryMint --world $WORLD_ADDRESS --keystore $STARKNET_KEYSTORE --password $KEYSTORE_PWD
sozo auth writer BriqFactoryStore BriqFactoryMint --world $WORLD_ADDRESS --keystore $STARKNET_KEYSTORE --password $KEYSTORE_PWD

sozo auth writer ERC721Balance set_nft_assembly --world $WORLD_ADDRESS --keystore $STARKNET_KEYSTORE --password $KEYSTORE_PWD
sozo auth writer ERC721Owner set_nft_assembly --world $WORLD_ADDRESS --keystore $STARKNET_KEYSTORE --password $KEYSTORE_PWD
sozo auth writer ERC1155Balance set_nft_assembly --world $WORLD_ADDRESS --keystore $STARKNET_KEYSTORE --password $KEYSTORE_PWD

sozo auth writer ERC721Balance set_nft_disassembly --world $WORLD_ADDRESS --keystore $STARKNET_KEYSTORE --password $KEYSTORE_PWD
sozo auth writer ERC721Owner set_nft_disassembly --world $WORLD_ADDRESS --keystore $STARKNET_KEYSTORE --password $KEYSTORE_PWD
sozo auth writer ERC1155Balance set_nft_disassembly --world $WORLD_ADDRESS --keystore $STARKNET_KEYSTORE --password $KEYSTORE_PWD

## approve EXECUTOR to spend 1eth FEE_TOKEN
starkli invoke $FEE_TOKEN_ADDR approve $FACTORY_ADDR u256:1000000000000000000 --keystore-password $KEYSTORE_PWD
starkli call $FEE_TOKEN_ADDR allowance $ACCOUNT_ADDRESS $FACTORY_ADDR

## Buy 1000 briqs with material_id=1 in briq_factory
# sozo execute BriqFactoryMint --world $WORLD_ADDRESS --calldata $ACCOUNT_ADDRESS,1,1000 --keystore $STARKNET_KEYSTORE --password $KEYSTORE_PWD
starkli invoke $FACTORY_ADDR buy 1 1000 --keystore-password $KEYSTORE_PWD

## ACCOUNT_ADDRESS balance : BRIQ
starkli call $BRIQ_ADDR balance_of $ACCOUNT_ADDRESS u256:1

starkli invoke $SET_ADDR assemble $ACCOUNT_ADDRESS 341987491384 1 str:toto 1 str:desc 1 1 1 1 1 1 0 --keystore-password $KEYSTORE_PWD

sozo execute set_nft_assembly --world $WORLD_ADDRESS \
    --calldata "8904,\
$ACCOUNT_ADDRESS,\
3417423384,\
1,23423,\
1,41343,\
1,1,1,\
1,1,1,\
0"\
    --keystore $STARKNET_KEYSTORE --password $KEYSTORE_PWD

## Upgrade

starkli invoke $FACTORY_ADDR upgrade $FACTORY_HASH --keystore-password $KEYSTORE_PWD
starkli invoke $SET_ADDR upgrade $SET_HASH --keystore-password $KEYSTORE_PWD
