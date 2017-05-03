#!/bin/bash

#SWARM_TOKEN=$(docker run swarm create)
#echo "SWARM_TOKEN: $SWARM_TOKEN" >> swarm_token.txt

# Creación de maquina Swarm Master
#docker-machine create -d g5k --g5k-resource-properties "cluster = 'chetemi' and memnode > 8192 and cpucore >= 4" --swarm --swarm-master --swarm-discovery token://$SWARM_TOKEN swarm-master


source g5k
docker-machine create -d g5k consul
docker-machine ls
site=$G5K_SITE

if docker-machine ls | grep consul ; then
	eval $(docker-machine env consul)
	docker run -d -p 8500:8500 -h consul --restart always gliderlabs/consul-server -bootstrap
else
	echo "couldn't create consul machine"
	exit 1
fi


#docker-machine create -d g5k --swarm --swarm-master --swarm-discovery="consul://$(docker-machine ip consul):8500" --g5k-image "ubuntu1404-x64-min" --engine-opt="cluster-store=consul://$(docker-machine ip consul):8500" --engine-opt="cluster-advertise=eth0:2376"  --g5k-resource-properties "cluster = 'chifflet' and memnode > 8192 and cpucore >= 4" --engine-opt "tlsverify=false" --engine-opt "tls=true" swarm-master
#docker-machine create -d g5k --swarm --swarm-discovery="consul://$(docker-machine ip consul):8500"  --g5k-image "ubuntu1404-x64-min" --engine-opt="cluster-store=consul://$(docker-machine ip consul):8500" --engine-opt="cluster-advertise=eth0:2376" --g5k-resource-properties "cluster = 'chifflet' and memnode > 8192 and cpucore >= 4" --engine-opt "tlsverify=false" --engine-opt "tls=true" swarm-worker-00
#docker-machine create -d g5k --swarm --swarm-discovery="consul://$(docker-machine ip consul):8500"  --g5k-image "ubuntu1404-x64-min" --engine-opt="cluster-store=consul://$(docker-machine ip consul):8500" --engine-opt="cluster-advertise=eth0:2376" --g5k-resource-properties "cluster = 'chifflet' and memnode > 8192 and cpucore >= 4" --engine-opt "tlsverify=false" --engine-opt "tls=true" swarm-worker-01
NODES=3
N=$((NODES - 1))




docker-g5k create-cluster --g5k-username "mgonzalez" \
    --g5k-password "***REMOVED***" \
    --g5k-reserve-nodes "$site:$NODES" \
    --swarm-standalone-enable \
    --swarm-standalone-discovery "consul://$(docker-machine ip consul):8500" \
    --engine-opt "$site-{0..$N}:cluster-store=consul://$(docker-machine ip consul):8500" \
    --engine-opt "$site-{0..$N}:cluster-advertise=eth0:2376" \
    --engine-opt "$site-{0..$N}:default-ulimit=nofile=8192:16384" --engine-opt "$site-{0..$N}:default-ulimit=nproc=8192:16384" --engine-opt "$site-{0..$N}:api-cors-header='*'" \
    --swarm-master "$site-0" \
    --g5k-image "ubuntu1404-x64-min" \
    --engine-opt "$site-{0..$N}:host=tcp://0.0.0.0:2375" --engine-opt "$site-{0..$N}:host=tcp://0.0.0.0:3376" --swarm-standalone-opt "tlsverify=false" \
    --swarm-standalone-opt "tls=true"

docker-machine ls


eval $(docker-machine env --swarm $site-0)

docker pull hyperledger/fabric-peer:x86_64-0.6.1-preview \
  && docker pull hyperledger/fabric-membersrvc:x86_64-0.6.1-preview \
  && docker pull yeasy/blockchain-explorer:latest \
  && docker tag hyperledger/fabric-peer:x86_64-0.6.1-preview hyperledger/fabric-peer \
  && docker tag hyperledger/fabric-peer:x86_64-0.6.1-preview hyperledger/fabric-baseimage \
  && docker tag hyperledger/fabric-membersrvc:x86_64-0.6.1-preview hyperledger/fabric-membersrvc \
  && docker pull magg/membership:latest && docker pull magg/eureka-fail:latest \
  && docker pull magg/peer-fail:latest \
  && docker pull magg/demo-node:latest  


for (( i=0; i<=$N; i++ ))
do
  docker-machine ssh $site-$i "sed -i '/tls/d' /etc/default/docker"
 docker-machine ssh $site-$i "sed -ie 's/--host=/-H /g' /etc/default/docker"
 docker-machine ssh $site-$i "sudo service docker restart"
  sleep 5
  docker-machine ssh $site-$i "sysctl -w net.ipv4.ip_forward=1"
done


#COMPOSE_HTTP_TIMEOUT=700 docker-compose  up --force-recreate --build




#docker-machine ssh worker-00 "docker pull hyperledger/fabric-peer:x86_64-0.6.1-preview " \
#"&& docker pull hyperledger/fabric-membersrvc:x86_64-0.6.1-preview " \
#"&& docker pull yeasy/blockchain-explorer:latest" \
#"&& docker tag hyperledger/fabric-peer:x86_64-0.6.1-preview hyperledger/fabric-peeri" \
#"&& docker tag hyperledger/fabric-peer:x86_64-0.6.1-preview hyperledger/fabric-baseimage" \
#"&& docker tag hyperledger/fabric-membersrvc:x86_64-0.6.1-preview hyperledger/fabric-membersrvc"

#./runDocker.sh

#./startDocker.sh

#docker-machine create -d g5k --g5k-resource-properties "cluster = 'chifflet' and memnode > 8192 and cpucore >= 4" master


#docker-machine create -d g5k --swarm --swarm-master --swarm-discovery="consul://$(docker-machine ip consul):8500" --engine-opt="cluster-store=consul://$(docker-machine ip consul):8500" --engine-opt="cluster-advertise=eth0:2376" swarm-master

#docker-machine create -d g5k --swarm --swarm-discovery="consul://$(docker-machine ip consul):8500" --engine-opt="cluster-store=consul://$(docker-machine ip consul):8500" --engine-opt="cluster-advertise=eth0:2376" swarm-worker-00

#eval $(docker-machine env --swarm swarm-master)

#docker-machine ssh master "docker swarm init --advertise-addr eth0:2377"

#eval $(docker-machine env swarm-master)

#docker swarm init \
#    --advertise-addr eth0:2377 \
#    --listen-addr $(docker-machine ip master):2377


#for i in 0 1 2; do
#  docker-machine create -d g5k --g5k-resource-properties "cluster = 'chifflet' and memnode > 8192 and cpucore >= 4" worker-0$i
#  docker-machine ssh worker-0$i "docker swarm join --token `docker $(docker-machine config master) swarm join-token worker -q` $(docker-machine ip master)"
#done

#docker-machine scp ./docker-compose-3.yml  master:/home/docker/.

#for i in 0 1 2 3; do
#    eval $(docker-machine env swarm-agent-0$i)

#    docker swarm join --token $TOKEN $(docker-machine ip swarm-master):2377
#done

#TOKEN=$(docker swarm join-token -q worker)


#docker deploy --compose-file docker-compose.yml myapp
