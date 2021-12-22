FROM python:3.9-buster

WORKDIR /usr/src/app

COPY requirements.txt ./
RUN pip install --no-cache-dir -r requirements.txt
# somehow necessary
RUN pip uninstall -y lark-parser && pip install lark-parser

COPY starknet_proxy/ starknet_proxy
COPY gunicorn.conf.py gunicorn.conf.py

CMD [ "gunicorn", "starknet_proxy.server:app" ]
