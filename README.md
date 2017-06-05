# Docker-Mongodb-Replica-Set

Create a three-member Mongodb replica set

Requirements:
1. Docker (>= 1.12) - Visit the Docker Docs to download for your OS
2. VirtualBox - https://www.virtualbox.org/wiki/Downloads
3. Have the following three docker machines running

* $ docker-machine create -d virtualbox manager
* $ docker-machine create -d virtualbox workerA
* $ docker-machine create -d virtualbox workerB

To Setup Replica Set: 
<br>
./init_replica_set.sh

To Tear down replica set: 
<br>
./reset_replica.set.sh

<br>

Blog Post explaining the script: [Create a MongoDB Replica Set with Docker](http://www.anishdalal.com/create-a-mongodb-replica-set-with-docker/)




