# Running tests

## Create environment by using Docker
Wake up docker container from the project root directory:
```
$ docker-compose build && docker-compose up -d
```
Or just run
```
$ docker-compose up -d
```
## Run tests
```
$ docker exec -ti sscp-test

0 ✓ sscp
$ bats /code/bats.sh
```
Or just run:
```
$ docker exec sscp-test bats /code/bats.sh
```
