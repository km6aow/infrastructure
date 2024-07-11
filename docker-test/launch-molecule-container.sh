#!/bin/bash

# All the incantations to get a molecule container to run for testing purposes

docker run -it --rm \
  --volume=/home/mklein/infrastructure:/infrastructure \
  --volume=/sys/fs/cgroup:/sys/fs/cgroup:rw  \
  --privileged \
  --cgroupns=host \
  molecule:latest
