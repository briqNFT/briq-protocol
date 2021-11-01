FROM python:3.7-buster

WORKDIR /usr/src/app

COPY requirements.txt ./
RUN pip install --no-cache-dir -r requirements.txt

COPY starknet_proxy/ starknet_proxy
COPY briq_abi.json briq_abi.json
COPY set_abi.json set_abi.json
COPY gunicorn.conf.py gunicorn.conf.py

ENV ADDRESS="0x075157ee904c59f9b4f5a2f284284fed3c05e0cc6446fd6578e753554a7a638f"
ENV SET_ADDRESS="0x002f988869e8e5466cea7cbb52dd3b9e45137eb762afa4f5ae69de1fb55679f7"

# Create folder to store JSON files
#RUN mkdir temp
# TODO: for now this will hardcode those so that we can get them.
COPY temp temp

CMD [ "gunicorn", "starknet_proxy.proxy:app" ]
