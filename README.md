# Greenplum Database single node Docker image 

This is a simple Greenplum Database single node docker image for local development.

DockerHub - https://hub.docker.com/r/ionxwood/greenplum

**docker-compose.yaml**
```yaml
---
version: "2.4"

services:
  greenplum:
    hostname: greenplum
    image: ionxwood/greenplum:6.21.0
    user: "root"
    restart: "always"
    ports: [ "5432:5432" ]
    networks: [ "greenplum" ]
    volumes: [ "greenplum:/srv" ]
    environment:
      MALLOC_ARENA_MAX: 1
      TZ: UTC
      GP_DB: test
      GP_USER: postgres
      GP_PASSWORD: postgres

networks:
  greenplum:

volumes:
  greenplum:
```
