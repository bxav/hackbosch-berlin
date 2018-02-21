#!/bin/bash -x
#
#

export $(egrep -v '^#' .env | xargs)

echo $PROJECT_NAME

[ -d .tmp ] || mkdir .tmp
docker save -o .tmp/image.tar azureiotpcs/pcs-remote-monitoring-webui:$PROJECT_NAME

sshpass -p `echo $PROJECT_PASSWORD | base64 -d` scp .tmp/image.tar "$PROJECT_USERNAME@$PROJECT_VM_IP:~" || echo "Fail Copy"
sshpass -p `echo $PROJECT_PASSWORD | base64 -d` ssh -tt "$PROJECT_USERNAME@$PROJECT_VM_IP" <<EOF
sudo docker load --input image.tar;
cd /app;
sed 's/azureiotpcs\/pcs-remote-monitoring-webui:1.0.0-preview.3/azureiotpcs\/pcs-remote-monitoring-webui:$PROJECT_NAME/' docker-compose.yml | sudo tee docker-compose.yml;
sudo ./start.sh
EOF
