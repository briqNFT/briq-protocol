FROM python:3.9-buster

WORKDIR /usr/src/app

COPY requirements.txt ./
RUN pip install --no-cache-dir -r requirements.txt

COPY starknet_proxy/ starknet_proxy
COPY briq_abi.json briq_abi.json
COPY set_abi.json set_abi.json
COPY gunicorn.conf.py gunicorn.conf.py

ENV ADDRESS="0x0260f002c898119b104c190bf0c1367fbb20ee007b7abb850cf0f2a098666e49"
ENV SET_ADDRESS="0x06e8dd268c2c1306a40eb212244112c7d2792c39382058db21e2267ce71a3fd9"

CMD [ "gunicorn", "starknet_proxy.server:app" ]
