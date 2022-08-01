# Run the starknet node and save/load it durably.
# Run woithout load-path to reinit:
# starknet-devnet --dump-path devnetstate --accounts 1 --dump-on exit
starknet-devnet --dump-path devnetstate --accounts 0 --dump-on exit --load-path devnetstate
