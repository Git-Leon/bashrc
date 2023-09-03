#!/bin/bash
# docker images -a -q | % { docker image rm $1 -f }
# Check if an image name is provided as an argument
if [ $# -ne 2 ]; then
  echo "Usage: $0 <name_of_image_to_restart> <name_of_new_container>"
  exit 1
fi

# Define the image name
IMAGE_NAME="$1"
CONTAINER_NAME="$2"

# Remove any existing containers with the same image name
CONTAINER_ID=$(docker ps -a -q --filter ancestor="$IMAGE_NAME")
if [ -n "$CONTAINER_ID" ]; then
  echo "Stopping and removing containers based on image '$IMAGE_NAME'..."
  docker stop "$CONTAINER_ID" > /dev/null 2>&1
  docker rm "$CONTAINER_ID" > /dev/null 2>&1
fi

# Build the Docker container using the Dockerfile in the current directory
echo "Building the Docker container from image '$IMAGE_NAME'..."
docker build -t "$CONTAINER_NAME" .

# Run a new container based on the specified image
echo "Running a new container based on image '$IMAGE_NAME'..."
docker run -d -p 8080:8080 --name "$IMAGE_NAME" "$CONTAINER_NAME"

echo "Container based on image '$IMAGE_NAME' started and running on port 8080."