# Briq Protocol

This repository contains the Cairo code for briq StarkNet contracts.

This is currently ongoing substantial changes.

## Setup

#### Install python environment (via venv)
```sh
python3 -m venv venv
source venv/bin/activate
pip3 install -r requirements.txt
```

## Deployment

- Deploy backend contract, with your wallet address as the proxy address
- Deploy proxy contracts, hard-coding the backend adress in the contract.
- Update the backend contracts proxy to the proxy.
- Deploy the rest of the ecosystem.
