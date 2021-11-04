FROM python:3.9-buster

WORKDIR /usr/src/app

COPY requirements.txt ./
RUN pip install --no-cache-dir -r requirements.txt

COPY starknet_proxy/ starknet_proxy
COPY briq_abi.json briq_abi.json
COPY set_abi.json set_abi.json
COPY gunicorn.conf.py gunicorn.conf.py

ENV ADDRESS="0x04f7c942cae0223aafbc7758c5a2209cfed61dfb5775bba9cdc89fd11b7503b1"
ENV SET_ADDRESS="0x04401243fc0f24e616b2fd798fb3c7be5dd4d6accf72d50a00c9fb5149560016"

CMD [ "gunicorn", "starknet_proxy.proxy:app" ]
