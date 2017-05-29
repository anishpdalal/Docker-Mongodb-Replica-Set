# Step 1) - Create Docker Volume
# Step 2) - Create Primary Member of Replica Set

function switchVM {
  env='docker-machine env '$1
  echo 'switched to $1'
  eval $($env)
}

# @params server container volume
function createContainer {
  switchVM $1
  addConfigFilesToContainer $2 $3
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
function setupAndStartContainer{
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
}

main
