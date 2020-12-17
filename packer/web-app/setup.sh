#!/bin/bash
sudo apt-get -qq update

sudo apt-get install \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg-agent \
    software-properties-common -y

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -

sudo apt-key fingerprint 0EBFCD88

sudo add-apt-repository \
   "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
   $(lsb_release -cs) \
   stable"

sudo apt-get -qq update
sudo apt-get install docker-ce=5:19.03.14~3-0~ubuntu-focal docker-ce-cli=5:19.03.14~3-0~ubuntu-focal containerd.io -y

sudo systemctl enable --now docker
sudo usermod -aG docker ubuntu

sudo docker pull nginx:alpine

sudo curl -L "https://github.com/docker/compose/releases/download/1.27.4/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

sudo mv /tmp/yaxkukmo.service /etc/systemd/system/
sudo mv /tmp/docker-compose.yml /home/ubuntu/docker-compose.yml

sudo systemctl enable yaxkukmo

sudo apt-get autoremove -y