# Step 1) - Create Docker Volume

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
