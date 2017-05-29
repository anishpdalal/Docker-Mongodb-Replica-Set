# Step 1) - Create Docker Volume
# Step 2) - Create Primary Member of Replica Set

function switchVM {
  env='docker-machine env '$1
  echo 'switched to $1'
  eval $($env)
}

# @params server container volume
function createContainer {
  # start container
  docker run --name $1 -v $2:/data -d mongo --smallfiles

}

# @params container volume
function addConfigFilesToContainer {
  echo 'Starting container '$1

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
