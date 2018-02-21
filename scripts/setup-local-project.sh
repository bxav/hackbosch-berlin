#!/bin/bash -x
#
# Setup a new IoT PCS Custom solution locally and setup a basic demo plan

solutionrepo="https://github.com/Azure/azure-iot-pcs-remote-monitoring-dotnet.git"
solutioncommit="ce4d34ad722b16321a31675314403f2f1e196c45"
clirepo="https://github.com/bxav/iot-cli.git"
webuirepo="https://github.com/bxav/iot-webui.git"
simulationrepo="https://github.com/bxav/device-simulation-dotnet.git"
scriptsrepo="https://github.com/bxav/iot-scripts.git"
clirepobranch="dev"

#[ -z $AZURE_SUBSCRIPTION_ID ] && echo "AZURE_SUBSCRIPTION_ID is not set" && exit 1

[ -n "$PROJECT_NAME" ] || PROJECT_NAME=$1
[ -n "$PROJECT_NAME" ] || read -p "Enter your project name: " PROJECT_NAME
[ -n "$PROJECT_LANGUAGE" ] || read -p "Enter the language (en,fr): " PROJECT_LANGUAGE
[ -n "$PROJECT_LOCATION" ] || read -p "Enter the location (ex: West Europe): " PROJECT_LOCATION
[ -n "$PROJECT_USERNAME" ] || read -p "Enter the admin username: " PROJECT_USERNAME

if [ -z $PROJECT_PASSWORD ]
then
    # read password twice
    read -s -p "Enter the admin password: " password
    echo 
    read -s -p "Password (again): " password2

    # check if passwords match and if not ask again
    while [ "$password" != "$password2" ];
    do
        echo 
        echo "Please try again"
        read -s -p "Password: " password
        echo
        read -s -p "Password (again): " password2
    done

    PROJECT_PASSWORD=$password
fi

webuibranch="base_${PROJECT_LANGUAGE}"
simulatorbranch="base_${PROJECT_LANGUAGE}"

# Create and checkout the Azure IoT solution
[ -d project ] || mkdir project
cd project
git clone --recursive $solutionrepo $PROJECT_NAME
cd $PROJECT_NAME
git checkout -b dev $solutioncommit

git clone -b $clirepobranch $clirepo cli-custom 

# Set up command line
cd cli-custom
npm install
npm start

# Sign into the Azure account
npm run main login

# Install the basic solution
node ./publish/index.js \
    -t remotemonitoring \
    -s basic \
    --solution-name $PROJECT_NAME \
    --website-name "${PROJECT_NAME}-${RANDOM}" \
    --subscription-id $AZURE_SUBSCRIPTION_ID \
    -l "$PROJECT_LOCATION" \
    -u $PROJECT_USERNAME \
    -p $PROJECT_PASSWORD \

# Checkout webui custom repo
cd ..
git clone -b $webuibranch $webuirepo webui-custom 
git clone -b $simulatorbranch $webuirepo simulator-custom 
git clone $scriptsrepo scripts-custom

# Create .env file
printf "\n# Env files\n.env\n.tmp" >> .gitignore

cat <<EOF > .env
AZURE_SUBSCRIPTION_ID=$AZURE_SUBSCRIPTION_ID
PROJECT_NAME=$PROJECT_NAME
PROJECT_LANGUAGE=$PROJECT_LANGUAGE
PROJECT_USERNAME=$PROJECT_USERNAME
PROJECT_PASSWORD=`echo $PROJECT_PASSWORD | base64`
PROJECT_VM_IP=NEED_TO_FIND_IT
EOF

az resource list --resource-group $PROJECT_NAME -o table