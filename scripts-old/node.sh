# Run the starknet node and save/load it durably.
# Run without load-path to reinit:
# starknet-devnet --dump-path devnetstate --accounts 1 --dump-on transaction
starknet-devnet --dump-path devnetstate --accounts 0 --dump-on transaction --load-path devnetstate
