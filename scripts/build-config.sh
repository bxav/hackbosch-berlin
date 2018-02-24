#!/bin/bash -x
#
#

export $(egrep -v '^#' .env | xargs)

cd config-custom

bash ./scripts/docker/build

docker tag azureiotpcs/pcs-config-dotnet:testing azureiotpcs/pcs-config-dotnet:$PROJECT_NAME && echo "Image tagged"
