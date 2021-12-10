FROM python:3.9-buster

WORKDIR /usr/src/app

COPY requirements.txt ./
RUN pip install --no-cache-dir -r requirements.txt
# somehow necessary
RUN pip uninstall -y lark-parser && pip install lark-parser

COPY starknet_proxy/ starknet_proxy
COPY briq_abi.json briq_abi.json
COPY set_abi.json set_abi.json
COPY gunicorn.conf.py gunicorn.conf.py

ENV ADDRESS="0x01d6b126e22d2f805a64fa0ce53ddebcd37363d13ab89960bd2bf896dd2742d4"
ENV MINT_ADDRESS="0x03dbda16e85ad0d72cd54ffd2971b4e18e71a4f9d1d310cc8fd2deb564fc8a59"
ENV SET_ADDRESS="0x01618ffcb9f43bfd894eb4a176ce265323372bb4d833a77e20363180efca3a65"

CMD [ "gunicorn", "starknet_proxy.server:app" ]
