# Step 1) - Create Docker Volume
# Step 2) - Create Primary/Manager Member of Replica Set
# Step 3) - Initialize Replica Set in Primary Member
# Step 4) - Create Worker Nodes of Replica Set
# Step 5) - Add Worker VM Hosts to Replica Set within Primary Member

# @params vm
function switchVM {
  env='docker-machine env '$1
  echo 'switched to '$1
  eval $($env)
}

# @params vm container volume
function createContainer {
  switchVM $1
  addConfigFilesToContainer $2 $3
  setupAndStartContainer $2 $3
}

# @params container volume
function addConfigFilesToContainer {
  echo 'Starting container '$1

  # start container
  docker run --name $1 -v $2:/data -d mongo --smallfiles

  # create folders in container where config files will be stored
  docker exec -i $1 bash -c 'mkdir /data/keyfile /data/admin'

  # copy config files into created folders
  docker cp config/admin.js $1:/data/admin/
  docker cp config/replica.js $1:/data/admin/
  docker cp config/mongo-keyfile $1:/data/keyfile/
  docker cp config/movies.js $1:/data/admin


  # stop docker container so it can be restarted with additional configs and settings for authentication
  docker stop $1
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


  echo 'starting up container '$1

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
  docker exec -i $2 bash -c 'mongo < /data/admin/replica.js'
  sleep 2
  # Load in admin users
  docker exec -i $2 bash -c 'mongo < /data/admin/admin.js'
  # Command for checking status of the replica set
  cmd='mongo -u $MONGO_REPLICA_ADMIN -p $MONGO_PASS_REPLICA --eval "rs.status()" --authenticationDatabase "admin"'
  sleep 2
  docker exec -i $2 bash -c "$cmd"

}

# @params vm container
function addReplicasInManagerNode {
  # Add replicas to the manager node that is on the manager VM
  switchVM $1
  for server in workerA workerB
  do
    rs="rs.add('$server:27017')"
    cmd='mongo --eval "'$rs'" -u $MONGO_REPLICA_ADMIN -p $MONGO_PASS_REPLICA --authenticationDatabase="admin"'
    sleep 2
    docker exec -i $2 bash -c "$cmd"
  done
}

# @params volume
function createDockerVolume {
  cmd=$(docker volume ls -q | grep $1)
  if [[ "$cmd" == $1 ]];
  then
    echo 'volume already created'
  else
    cmd='docker volume create --name '$1
    eval $cmd
  fi
}

function main {
  createDockerVolume mongodb_volume
  createContainer manager managerNode mongodb_volume
  initializeReplicaSet manger managerNode
  createContainer workerA workerNodeA mongodb_volume
  createContainer workerB workerNodeB mongodb_volume
}

main
