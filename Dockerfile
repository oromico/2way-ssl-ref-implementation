FROM ubuntu:18.04 AS ref2wayssl_base

LABEL maintainer="Chee-Wee Khoo <cheewee.khoo@oromico.com>"

### bootstrap Ubuntu
# update ubuntu
RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y less vim sudo systemd traceroute wget libssl-dev locales python3-pip

# add locale
RUN sed -i -e 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen && \
    locale-gen && \
    update-locale LANG=en_US.UTF-8 && \
    update-locale LC_ALL=en_US.UTF-8 && \
    update-locale LC_CTYPE=en_US.UTF-8

### install and setup nginx
# install
RUN apt-get install -y nginx

# setup nginx
RUN mkdir -p /mnt/transient/log/nginx

COPY ./nginx/nginx.conf /etc/nginx/nginx.conf

RUN mkdir -p /etc/nginx/ssl/certs
COPY ./certs/server.crt /etc/nginx/ssl/certs/server.crt
COPY ./certs/server.key /etc/nginx/ssl/certs/server.key

RUN mkdir -p /etc/nginx/ssl/trust
COPY ./certs/ca.crt /etc/nginx/ssl/trust/ca.crt

# setup site
COPY ./nginx/site_default.conf /etc/nginx/sites-available/default
RUN ln -f -s /etc/nginx/sites-available/default /etc/nginx/sites-enabled/default

### setup supervisor
RUN mkdir -p /mnt/transient/log/supervisord

RUN apt-get install -y supervisor

FROM ref2wayssl_base:latest AS ref2wayssl

COPY ./supervisord/supervisord.conf /etc/supervisor/supervisord.conf

### setup and install API server app
RUN mkdir -p /mnt/app/demoapiserver
RUN mkdir -p /mnt/transient/log/app

ADD ./server/setup.py /mnt/app/demoapiserver
ADD ./server/requirements.txt /mnt/app/demoapiserver
ADD ./server/demoapiserver /mnt/app/demoapiserver/demoapiserver

# install
WORKDIR /mnt/app/demoapiserver
RUN python3 setup.py install

### execute supervisor
ENTRYPOINT ["supervisord", "-c","/etc/supervisor/supervisord.conf"]
