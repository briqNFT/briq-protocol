FROM python:3.9-buster

WORKDIR /usr/src/app

COPY requirements.txt ./
RUN pip install --no-cache-dir -r requirements.txt

COPY starknet_proxy/ starknet_proxy
COPY briq_abi.json briq_abi.json
COPY set_abi.json set_abi.json
COPY gunicorn.conf.py gunicorn.conf.py

ENV ADDRESS="0x04a0ed17b7453e304261df18633bdb7fd8c8275f42f254e9f4674e85736c65ae"
ENV SET_ADDRESS="0x01a7c1ddc1597b41479fbf24ee93dab0d850db0dfa41012cab267d2be6b809cf"

CMD [ "gunicorn", "starknet_proxy.server:app" ]
