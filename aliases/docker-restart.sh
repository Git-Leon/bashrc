#!/bin/bash
# docker images -a -q | % { docker image rm $1 -f }

# Check if a repository name is provided as an argument
if [ $# -ne 1 ]; then
  echo "Usage: $0 <repository_name>"
  exit 1
fi

# Define the repository name
REPOSITORY_NAME="$1"

# Find the image IDs for the specified repository name
IMAGE_IDS=$(docker images | awk -v repository="$REPOSITORY_NAME" '$1 == repository {print $3}')

# Check if any images were found for the specified repository
if [ -z "$IMAGE_IDS" ]; then
  echo "No images found for repository '$REPOSITORY_NAME'."
  exit 1
fi

# Stop and remove containers based on the found image IDs
for IMAGE_ID in $IMAGE_IDS; do
  CONTAINER_ID=$(docker ps -a -q --filter ancestor="$IMAGE_ID")
  if [ -n "$CONTAINER_ID" ]; then
    echo "Stopping and removing containers based on image ID '$IMAGE_ID'..."
    docker stop "$CONTAINER_ID" > /dev/null 2>&1
    docker rm "$CONTAINER_ID" > /dev/null 2>&1
  fi
done

# Build a Docker container using the specified repository name
echo "Building a Docker container from repository '$REPOSITORY_NAME'..."
docker build -t "$REPOSITORY_NAME" .

# Run a new container based on the specified repository name
echo "Running a new container based on repository '$REPOSITORY_NAME'..."
docker run -d -p 8080:8080 --name "$REPOSITORY_NAME" "$REPOSITORY_NAME"

echo "Container based on repository '$REPOSITORY_NAME' started and running on port 8080."