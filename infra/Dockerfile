FROM python:3.9-buster

WORKDIR /usr/src/app

COPY requirements.txt ./
RUN pip install --no-cache-dir -r requirements.txt

COPY starknet_proxy/ starknet_proxy
COPY briq_abi.json briq_abi.json
COPY set_abi.json set_abi.json
COPY gunicorn.conf.py gunicorn.conf.py

ENV ADDRESS="0x003673b845ed7583de3f2cc8cc3bc281c807808ca46e694d385eeb623f2a6cd4"
ENV SET_ADDRESS="0x0410361304c4a754e9dc87b43a816c731624eb1409d90e72e93ab798b2d4e164"

CMD [ "gunicorn", "starknet_proxy.server:app" ]
