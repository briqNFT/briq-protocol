FROM python:3.9-buster

WORKDIR /usr/src/app

COPY requirements.txt ./
RUN pip install --no-cache-dir -r requirements.txt

COPY starknet_proxy/ starknet_proxy
COPY briq_abi.json briq_abi.json
COPY set_abi.json set_abi.json
COPY gunicorn.conf.py gunicorn.conf.py

ENV ADDRESS="0x05fd6b2390ebb20145309db6e58ca4e696dfac3b3525750ad7e8f31ef125506a"
ENV SET_ADDRESS="0x07309cc705f05e9ae6e2ab4ac447fa8a783e621d21a13793187773cd93ac9438"

CMD [ "gunicorn", "starknet_proxy.server:app" ]
