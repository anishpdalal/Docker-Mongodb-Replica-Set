admin = db.getSiblingDB("admin")
admin.createUser(
  {
    user: "anish",
    pwd: "e2iLv#37k9j5",
    roles: [ { role: "userAdminAnyDatabase", db: "admin" } ]
  }
)

db.getSiblingDB("admin").auth("anish", "e2iLv#37k9j5" )

db.getSiblingDB("admin").createUser(
  {
    "user" : "replicaAdmin",
    "pwd" : "879879JQj#Oj",
    roles: [ { "role" : "clusterAdmin", "db" : "admin" } ]
  }
)
