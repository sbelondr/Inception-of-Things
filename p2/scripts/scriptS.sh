#!/bin/bash

yum install -y vim
# bug in the last release - https://github.com/k3s-io/k3s/issues/5912
curl -sfL https://get.k3s.io > script.sh
INSTALL_K3S_COMMIT=30fc909581ba8395da0860c22830d9db3913f7b1 sh script.sh \
				 --node-external-ip 192.168.42.110 \
				 --node-ip 192.168.42.110 \
				 --selinux --write-kubeconfig-mode "0644"
# use k3s with vagrant user
chmod 755 /etc/rancher/k3s/k3s.yaml
echo "alias k=kubectl" >> /home/vagrant/.bashrc
/usr/local/bin/kubectl completion bash >> /home/vagrant/.bashrc

# install ingress nginx
/usr/local/bin/kubectl apply -f \
  https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.3.0/deploy/static/provider/cloud/deploy.yaml

# wait service is started
echo "Wait 30s"
sleep 60
/usr/local/bin/kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=120s

# launch provisionning
chmod +x create_volume_map.sh
./create_volume_map.sh
/usr/local/bin/kubectl apply -f app1/app1.yaml
/usr/local/bin/kubectl apply -f app2/app2.yaml
/usr/local/bin/kubectl apply -f app3/app3.yaml
