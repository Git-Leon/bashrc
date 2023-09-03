#!/bin/bash
# docker images -a -q | % { docker image rm $1 -f }
# Check if an image name is provided as an argument
if [ $# -ne 1 ]; then
  echo "Usage: $0 <name_of_image_to_delete>"
  exit 1
fi

# Define the image name
IMAGE_NAME="$1"

# Remove any existing containers with the same image name
CONTAINER_ID=$(docker ps -a -q --filter ancestor="$IMAGE_NAME")
if [ -n "$CONTAINER_ID" ]; then
  echo "Stopping and removing containers based on image '$IMAGE_NAME'..."
  docker stop "$CONTAINER_ID" > /dev/null 2>&1
  docker rm "$CONTAINER_ID" > /dev/null 2>&1
fi