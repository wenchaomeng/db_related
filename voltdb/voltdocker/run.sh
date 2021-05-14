
TAG=9.2.1

# create network
if !  docker network list | egrep voltLocalCluster ; then
	echo not exist create one	
	docker network create -d bridge voltLocalCluster
fi


#voltLocalCluster
for id in `docker ps | egrep volt | awk '{print $1}'`
do
	echo kill $id
	docker kill $id
	docker rm $id
done
docker rm node1 node2 node3
docker run -d -P -e HOST_COUNT=3 -e HOSTS=node1,node2,node3  -v /Users/mengwenchao/Documents/db/voltdb/data:/data --name=node1 --network=voltLocalCluster voltdb/voltdb-community:$TAG
docker run -d -P -e HOST_COUNT=3 -e HOSTS=node1,node2,node3 --name=node2 --network=voltLocalCluster voltdb/voltdb-community:$TAG
docker run -d -P -e HOST_COUNT=3 -e HOSTS=node1,node2,node3 --name=node3 --network=voltLocalCluster voltdb/voltdb-community:$TAG

sleep 1

echo after start all docker instances
docker ps

# read data
SLEEP=8
echo wait $SLEEP seconds to import data 
sleep $SLEEP
docker exec -i node1 bash << EOF
sqlcmd < /data/table.sql > /dev/null
sqlcmd < /data/data.sql > /dev/null
EOF

#Interface	Port #
#Client Port	21212
#Admin Port	21211
#Web Interface Port (httpd)	8080
#Internal Server Port	3021
#Replication Port	5555
#Zookeeper port	7181
#SSH	22

#docker port node1 21212/tcp -> 0.0.0.0:21212 8080/tcp -> 0.0.0.0:8081


