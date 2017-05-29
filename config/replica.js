rs.initiate(
  {
    _id: 'curriculumReplSet',
    members: [
      {_id: 0, host: 'manager:27017'}
    ]
  }
)
