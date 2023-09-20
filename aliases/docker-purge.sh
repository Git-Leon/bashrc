#!/bin/bash
docker images
docker rmi -f $(docker images -a -q)
docker images