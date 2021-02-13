# docker.elasticsearch
![build status](https://github.com/leandropadua/docker.elasticsearch/workflows/ci/badge.svg)

This repository can be used to build an Elasticsearch docker image from the source code.

Versions used:
- openjdk 8
- gradle 3.3
- elasticsearch 6.0.0

## Pre requisites
To build the image a minimum of *4GB of RAM* is needed due to gradle usage.
It can't be limited or reduced due to [Gradle 3 limitation](https://github.com/gradle/gradle/issues/5102).

## Quick start
```sh
# build
docker build -t leandro_es:latest .

# run (it take a minute to initialise)
docker run --rm -it -p 9200:9200 leandro_es

# check container health
curl 127.0.0.1:9200/_cluster/health

# push some data
curl -POST http://localhost:9200/my_index/my_type/id1 -curl -H 'Content-Type: application/json' -d '{"user":"Leandro","message":"Hello World!"}'

# read the data
curl -GET http://localhost:9200/my_index/my_type/id1
```

## configuration
The container is bootstrapped with a [standard configuration](./config/elasticsearch.yml) to allow single node execution from a container.

## continuous integration
This repository is automated by github actions and any push to main would publish the [image to dockerhub](https://hub.docker.com/r/leandropadua/elasticsearch).
```sh
docker pull leandropadua/elasticsearch:6.0.0
```

## limitations
For simplicity, no plugins are loaded by default, including xpack. Any plugin should be enabled in the entrypoint, if that is needed.
