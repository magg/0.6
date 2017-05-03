#!/bin/bash

source g5k
site=$G5K_SITE

docker-machine ssh $site-0 "apt-get install git make -y && git clone http://gerrit.hyperledger.org/r/cello && cd cello"

docker-machine ssh $site-0 "docker pull python:3.5 \
	&& docker pull mongo:3.2 \
	&& docker pull yeasy/nginx:latest \
	&& docker pull mongo-express:0.30"


docker-machine ssh $site-0 "cd cello && make setup"

docker-machine ssh $site-0 "cd cello && make restart"
