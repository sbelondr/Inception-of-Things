#!/bin/bash

# get token k3s server
scp -i /tmp/ssh/id_rsa -o StrictHostKeyChecking=no \
	vagrant@192.168.42.110:token /tmp/token

curl -sfL https://get.k3s.io > script.sh

# install k3s agent
INSTALL_K3S_NAME="k3s-agent" K3S_TOKEN_FILE="/tmp/token" \
	K3S_URL="https://192.168.42.110:6443" sh script.sh \
	--node-external-ip 192.168.42.111 \
	--node-ip 192.168.42.111

# set role to the new agent
ssh -o StrictHostKeyChecking=no \
	-i /tmp/ssh/id_rsa vagrant@192.168.42.110 \
	"kubectl label node sbelondrsw node-role.kubernetes.io/worker=worker"

# Add kubeconfig
scp -i /tmp/ssh/id_rsa -o StrictHostKeyChecking=no vagrant@192.168.42.110:/etc/rancher/k3s/k3s.yaml /home/vagrant/k3s.yaml
sed -i 's/127.0.0.1/192.168.42.110/g' /home/vagrant/k3s.yaml
echo "export KUBECONFIG=/home/vagrant/k3s.yaml" >> /home/vagrant/.bashrc
chown vagrant:vagrant /home/vagrant/k3s.yaml
