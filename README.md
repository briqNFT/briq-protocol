# Briq Protocol

This repository contains the Cairo code for briq StarkNet contracts.

This is currently ongoing substantial changes.

## Setup

Nile is used to handle deployment and compiling.
#### Install python environment (via venv)
```sh
python3 -m venv venv
source venv/bin/activate
pip3 install -r requirements.txt
```

## Deployment

```sh
nile run scripts/deploy.sh
```

Test run:
```sh
SIGNER=123456 nile send SIGNER mint mint_amount [signer_address] 50

```