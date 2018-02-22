#!/bin/bash -x
#
#

export $(egrep -v '^#' .env | xargs)

cd simulation-custom

bash ./scripts/docker/build

docker tag azureiotpcs/device-simulation-dotnet:testing azureiotpcs/device-simulation-dotnet:$PROJECT_NAME && echo "Image tagged"
