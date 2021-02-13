#!/bin/ash

STRUCTURIZR_VERSION=${1}
USERNAME=${2:-"automatic"}

CLI_DIR=/bin/structurizr/

set -e

apk update
apk add --no-cache openjdk11-jre

mkdir -p ./downloads
curl -L --create-dirs -o ./downloads/structurizr-cli.zip "https://github.com/structurizr/cli/releases/download/v${STRUCTURIZR_VERSION}/structurizr-cli-${STRUCTURIZR_VERSION}.zip"
mkdir -p ${CLI_DIR}
unzip ./downloads/structurizr-cli.zip -d ${CLI_DIR}
rm -R ./downloads

if [ "${USERNAME}" != "root" ]; then
    chown -R ${USERNAME}:${USERNAME} ${CLI_DIR}
fi

STRUCT_RC="$(cat << EOF
export PATH=\$PATH:${CLI_DIR}
EOF
)"

echo "${STRUCT_RC}" >> /etc/bash.bashrc
echo "${STRUCT_RC}" >> /etc/zsh/zshrc

# apt-get install wget apt-transport-https gnupg
# wget -qO - https://adoptopenjdk.jfrog.io/adoptopenjdk/api/gpg/key/public | sudo apt-key add -
# echo "deb https://adoptopenjdk.jfrog.io/adoptopenjdk/deb buster main" | sudo tee /etc/apt/sources.list.d/adoptopenjdk.list
# sudo apt-get update
# sudo apt-cache search adoptopenjdk-8
# sudo apt-get -y install --no-install-recommends adoptopenjdk-8-hotspot-jre
