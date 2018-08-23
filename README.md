# MultiJoinTest

## Run MySQL server on Docker

```
$ docker container run --rm -d \
      -e MYSQL_ROOT_PASSWORD=root_password \
      -e MYSQL_DATABASE=vapor \
      -p 43306:3306 \
      --name mysql \
      mysql:5.7
```
Project tests queries with multiple joins to the same table in MySQL and SQLite.
