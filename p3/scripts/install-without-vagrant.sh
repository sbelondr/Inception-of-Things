#!/bin/bash

# set env
KUB=/usr/local/bin/kubectl
K3D=/usr/local/bin/k3d

NS_ARGO=argocd
NS_DEV=dev

CLUSTER_NAME="part3"
PORT_HTTP=80
PORT_HTTPS=443
AGENTS=2
API_PORT=6443

DIR_CONFS="./confs"
DIR_INGRESS=$DIR_CONFS/ingress
DIR_SVC=$DIR_CONFS/svc
DIR_K3D=$DIR_CONFS/k3d
DIR_KUBECTL=$DIR_CONFS/kubectl
DIR_INSTALL=$DIR_CONFS/install

# bin install config
DIR_BIN="./tmp"
VERSION_KUB="v1.25.3"
URL_BIN_KUB="https://dl.k8s.io/release/$VERSION_KUB/bin/linux/amd64/kubectl"
URL_SHA_KUB="https://dl.k8s.io/$VERSION_KUB/bin/linux/amd64/kubectl.sha256"

install_requirement() {
	mkdir -p $DIR_BIN
	if [ ! -f "$KUB" ]; then
		pushd $DIR_BIN
			echo "Install kubectl ..."
			curl -LO $URL_BIN_KUB > /dev/null
			curl -LO $URL_SHA_KUB > /dev/null
			out=$(echo "$(cat kubectl.sha256)  kubectl" | sha256sum --check)
			if [ "kubectl: OK" == "$out" ]; then
				sudo install -o root -g root -m 0755 kubectl $KUB > /dev/null
			else
				echo "Error with kubectl install"
				exit 1
			fi
		popd
	fi
	pwd
	if [ ! -f "$K3D" ]; then
		echo "Install k3d ..."
		bash ./scripts/install-k3d.sh > /dev/null
	fi
	rm -rf $DIR_BIN
}

setup_k3d() {
	# install cluster
	$K3D cluster create --api-port $API_PORT \
		-p "$PORT_HTTP:80@loadbalancer" \
		-p "$PORT_HTTPS:443@loadbalancer" \
		-p "8081:8081@loadbalancer" \
		-p "8084:8084@loadbalancer" \
		--agents $AGENTS $CLUSTER_NAME
}

install_apps() {
	# create env
	$KUB create ns $NS_ARGO
	$KUB create ns $NS_DEV

	# install argocd - https://www.sokube.ch/post/gitops-on-a-laptop-with-k3d-and-argocd
	pushd $DIR_INSTALL
		$KUB apply -f argocd.yaml -n $NS_ARGO
	popd

	kubectl -n $NS_ARGO wait --for=condition=available \
		--timeout=9000s deployment.apps/argocd-server

	# apply svc
	pushd $DIR_SVC
		$KUB apply -f traefik.yaml
	popd


	# apply ingress routes
	pushd $DIR_INGRESS
		$KUB apply -f traefik.yaml
		$KUB apply -f argocd.yaml
	popd
	# edit password argocd
	$KUB -n $NS_ARGO patch secret argocd-secret \
	  -p '{"stringData": {
		"admin.password": "$2y$12$Kg4H0rLL/RVrWUVhj6ykeO3Ei/YqbGaqp.jAtzzUSJdYWT6LUh/n6",
		"admin.passwordMtime": "'$(date +%FT%T%Z)'"
	  }}'
}

print_info() {
	echo ""
	echo "Routes:"
	echo -e "\t Traefik: localhost:$PORT_HTTP/dashboard"
	echo -e "\t Argocd: localhost:$PORT_HTTP/argocd"
	echo "Password argocd is : mysupersecretpassword"
}

install_requirement
setup_k3d
install_apps
print_info
