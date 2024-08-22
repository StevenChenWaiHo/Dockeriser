#!/bin/bash
DOCKERFILE_HEADER_STRING=$(cat << EOF
version: '3'

services:
EOF
)

function get_plugin_docker_string () {
    PLUGIN_STRING=$(cat << EOF
    build-$FOLDER_NAME:
      labels:
        - "traefik.enable=false"
      image: pugpig/wpdev:v0
      restart: "no"
      volumes:
        - ./${FOLDER_PATH#./}:/$FOLDER_NAME
      user: app
      command: bash -c '''
          cd /$FOLDER_NAME
          && composer update --no-interaction
          && composer install --no-interaction
          && composer dumpautoload --optimize
          && composer test --no-interaction
          && npm ci
          && NO_GIT=1 npm run watch
        '''

EOF
)
}

function append_plugin_docker_string() {
    # Loop through each repository
    echo "Processing $FOLDER_NAME..."

    # Navigate to the repository directory
    cd "$FOLDER_PATH" || { echo "Failed to enter $FOLDER_PATH"; return; }

    # Check if there is a package.json file
    if [ ! -f "package.json" ]; then
        echo "$FOLDER_NAME directory is not a valid Node.js project (Cannot find the package.json file)"; 
        return;
    fi

    # Check if Dockerfile exists, if not create one
    if [ -f "docker-compose.yml" ]; then
        echo "docker file (docker-compose.yml) already exists try deleting it before running this script"
    fi

    # Create a basic Dockerfile (you might need to adjust this based on repo needs)
    get_plugin_docker_string
    DOCKERFILE_PLUGIN_STRING+="$PLUGIN_STRING\n\n"
}

# MAIN STARTS HERE

DOCKERFILE_PLUGIN_STRING=""

NODE_FOLDERS=($(find . -name "package.json" -exec dirname {} \;))

CURRENT_REPO=$(pwd)

for FOLDER_PATH in "${NODE_FOLDERS[@]}"; do
    FOLDER_NAME=$(basename $FOLDER_PATH)
    append_plugin_docker_string
    cd "$CURRENT_REPO"
done

echo "Creating Dockerfile"
echo -e "$DOCKERFILE_HEADER_STRING\n$DOCKERFILE_PLUGIN_STRING" > docker-compose.yml
