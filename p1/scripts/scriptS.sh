#!/bin/bash

curl -sfL https://get.k3s.io > script.sh
INSTALL_K3S_NAME="k3s" sh script.sh \
	--node-external-ip 192.168.42.110 \
	--node-ip 192.168.42.110

# set peermission to share token
cp /var/lib/rancher/k3s/server/node-token /home/vagrant/token
chmod 755 /home/vagrant/token

chown vagrant:vagrant /home/vagrant/token

# use k3s with vagrant user
chmod 755 /etc/rancher/k3s/k3s.yaml
