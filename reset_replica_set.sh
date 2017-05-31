function switchVM {
  env='docker-machine env '$1
  echo '···························'
  echo '·· swtiching '$1' docker machine ··'
  echo '···························'
  eval $($env)
}

function removeContainer {
  switchVM $1
  docker rm -f $2
  docker volume rm $(docker volume ls -qf dangling=true)
}

function main {
  removeContainer manager managerNode
  removeContainer workerA workerNodeA
  removeContainer workerB workerNodeB
  switchVM manager
}

main
