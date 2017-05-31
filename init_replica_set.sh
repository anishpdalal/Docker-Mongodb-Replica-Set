# Step 1) - Create Docker Volume
# Step 2) - Create Primary/Manager Member of Replica Set
# Step 3) - Initialize Replica Set in Primary Member
# Step 4) - Create Worker Nodes of Replica Set
# Step 5) - Add Worker VM Hosts to Replica Set within Primary Member

# @params vm
function switchVM {
  echo '..................................................'
  echo 'Switching to '$1
  echo '..................................................'
  env='docker-machine env '$1
  eval $($env)
}

# @params vm container volume
function createContainer {
  switchVM $1
  addConfigFilesToContainer $2 $3
  setupAndStartContainer $2 $3
  waitForMongodbToLoad $1
}

# @params vm
function waitForMongodbToLoad {
  ip=$(docker-machine ip $1)
  # make tcp call
  echo "Making TCP call to IP == $ip PORT == 27017"
  waitFor $ip 27017
}

# @params ip port
function waitFor {
  echo ">>>>>>>>>>> waiting for mongodb"
  while :
  do
    (echo > /dev/tcp/$1/$2) >/dev/null 2>&1
    result=$?
    if [[ $result -eq 0 ]]; then
        echo "MongoDb is now available on $2 in $1"
        sleep 3
        break
    fi
    sleep 5
  done
}



# @params container volume
function addConfigFilesToContainer {
  echo '..................................................'
  echo 'Creating container '$1
  echo '..................................................'

  # start container
  docker run --name $1 -v $2:/data -d mongo --smallfiles

  # create folders in container where config files will be stored
  echo '..................................................'
  echo 'Creating keyfile and admin directories within container '$1
  docker exec -i $1 bash -c 'mkdir /data/keyfile /data/admin'
  echo '..................................................'

  # copy config files into created folders
  docker cp config/admin.js $1:/data/admin/
  docker cp config/replica.js $1:/data/admin/
  docker cp config/mongo-keyfile $1:/data/keyfile/

  # change folder owner
  docker exec -i $1 bash -c 'chown -R mongodb:mongodb /data'

  # stop and remove docker container so it can be restarted with additional configs and settings for authentication
  echo '..................................................'
  echo 'Stopping container '$1
  docker stop $1
  echo 'Removing container '$1
  docker rm $1
  echo '..................................................'
}

function getHostIPs {
  hosts=''
  for host in manager workerA workerB
  do
      cmd='docker-machine ip '$host
      hosts=$hosts' --add-host '$host':'$($cmd)
  done

  echo $hosts

}

# @params container volume
function setupAndStartContainer {
  port='27017:27017'
  p='27017'
  replSet='curriculumReplSet'
  env='config/env'
  storageEngine='wiredTiger'
  hosts=$(getHostIPs)
  keyfile='mongo-keyfile'

  echo '..................................................'
  echo 'Re-starting container with additional configs'$1
  echo '..................................................'
  # start container with configs for authentication, replica set, port mapping, and hosts that it can reside in
  docker run --name $1 --hostname $1 \
  -v $2:/data \
  $hosts \
  --env-file $env \
  -p $port \
  -d mongo --smallfiles \
  --keyFile /data/keyfile/$keyfile \
  --replSet $replSet \
  --storageEngine $storageEngine \
  --port $p
}

# @params vm container
function initializeReplicaSet {
  switchVM $1
  sleep 2
  # Initialize replica set
  echo '..................................................'
  echo 'Initialize replica set'
  echo '..................................................'
  docker exec -i $2 bash -c 'mongo < /data/admin/replica.js'
  sleep 2
  echo '..................................................'
  echo 'Load in admin users'
  echo '..................................................'
  # Load in admin users
  docker exec -i $2 bash -c 'mongo < /data/admin/admin.js'

  # Command for checking status of the replica set
  echo 'checking for status of replica set..............'
  cmd='mongo -u $MONGO_REPLICA_ADMIN -p $MONGO_PASS_REPLICA --eval "rs.status()" --authenticationDatabase "admin"'
  sleep 2
  docker exec -i $2 bash -c "$cmd"

}

# @params manager_vm manager_container worker_vm
function addToReplicaSet {
  # Add replicas to the manager node that is on the manager VM
  echo 'Adding worker host '$3' to replica set...............'
  switchVM $1
  rs="rs.add('$3:27017')"
  cmd='mongo --eval "'$rs'" -u $MONGO_REPLICA_ADMIN -p $MONGO_PASS_REPLICA --authenticationDatabase="admin"'
  sleep 2
  waitForMongodbToLoad $3
  docker exec -i $2 bash -c "$cmd"
}

# @params volume
function createDockerVolume {
  echo '..................................................'
  echo "Creating docker volume for persisting config files"
  echo '..................................................'

  cmd=$(docker volume ls -q | grep $1)
  if [[ "$cmd" == $1 ]];
  then
    echo 'volume already created'
  else
    cmd='docker volume create --name '$1
    eval $cmd
  fi
  echo '..................................................'
  echo "Docker volume created"
  echo '..................................................'
}

function main {
  createDockerVolume mongodb_volume
  createContainer manager managerNode mongodb_volume
  initializeReplicaSet manager managerNode
  createContainer workerA workerNodeA mongodb_volume
  createContainer workerB workerNodeB mongodb_volume
  addToReplicaSet manager managerNode workerA
  addToReplicaSet manager managerNode workerB
}

main
