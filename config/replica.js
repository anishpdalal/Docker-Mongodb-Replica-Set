rs.initiate(
  {
    _id: 'curriculum_rs',
    members: [
      {_id: 0, host: 'manager:27017'},
      {_id: 1, host: 'workerA:27017'},
      {_id: 2, host: 'workerB:27017'}
    ]
  }
)
