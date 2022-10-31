#!/bin/bash

set -e

# PATH
KUB=/usr/local/bin/kubectl
K3D=/usr/local/bin/k3d
HELM=/usr/local/bin/helm

# env
CONFS="./confs"
SCRIPTS="./scripts"

# cluster config
CLUSTER_NAME="bonus"
CLUSTER_AGENT=1
CLUSTER_SERVER=1

# bin install config
DIR_BIN="./tmp"
VERSION_KUB="v1.25.3"
URL_BIN_KUB="https://dl.k8s.io/release/$VERSION_KUB/bin/linux/amd64/kubectl"
URL_SHA_KUB="https://dl.k8s.io/$VERSION_KUB/bin/linux/amd64/kubectl.sha256"
URL_SCRIPT_HELM="https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3"

# helm config
GITLAB_NAME="gitlab"
CERT_NAME="cert-manager"

# namespace
NS_DEV="dev"
NS_ARGO="argocd"
NS_GITLAB="gitlab"
NS_CERT="cert-manager"

welcome() {
	echo "⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣤⣶⣿⣿⣿⣿⣷⣦⡀⠀⠀⠀⠀⠀⠀⠀⠀  "
	echo "⠀⠀⠀⠀⠀⠀⠀⠀⢠⣿⣿⠟⠋⠉⠉⠉⠛⢿⣿⣦⡀⠀⠀⠀⠀⠀⠀  "⠀
	echo "⠀⠀⠀⠀⠀⠀⠀⠀⣾⣿⡏⠀⢰⣶⣶⣦⡀⠈⢿⣿⣧⠀⠀⠀⠀⠀⠀  "⠀
	echo "⠀⠀⠀⠀⠀⠀⠀⠀⠹⣿⣿⣄⡈⠉⣻⣿⣷⠀⢸⣿⣿⠀⠀⠀⠀⠀⠀  "⠀
	echo "⠀⠀⠀⠀⠀⠀⠀⠀⠀⠙⠿⣿⣿⣿⣿⡿⠃⠀⣼⣿⡿⠀⠀⠀⠀⠀⠀  "⠀
	echo "⠀⠀⠀⠀⠀⣀⣀⣀⣀⣀⣀⠀⠀⠀⠀⢀⣠⣾⣿⡿⠃⠀⠀⠀⠀⠀⠀  "⠀
	echo "⠀⠀⣀⣶⣿⣿⡿⠿⠿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠟⠀⢀⣀⣀⣀⠀⠀⠀  "⠀
	echo "⠀⣴⣿⣿⠋⠁⠀⣀⡀⠀⠙⢿⣿⣿⣿⣿⡟⠁⢀⣴⣿⣿⣿⣿⣿⣶⡄  "⠀
	echo "⢸⣿⣿⠁⠀⣴⣿⣿⣿⣷⣄⠀⢹⣿⣿⡟⠀⢀⣿⣿⡟⠁⡀⠈⠙⣿⣿⡆ "
	echo "⢸⣿⣿⠀⠘⣿⣿⡅⠙⣿⣿⡀⠀⢿⣿⣇⠀⠘⣿⣿⣷⣿⣿⠇⠀⣿⣿⡇ "
	echo "⠘⣿⣿⣆⠀⠉⠋⠁⣠⣿⣿⠃⠀⠘⣿⣿⣦⡀⠈⠛⠛⠛⠁⠀⣰⣿⣿⠃ "
	echo "⠀⠘⢿⣿⣿⣶⣶⣾⣿⡿⠋⠀⠀⠀⠈⠻⣿⣿⣶⣤⣤⣤⣴⣾⣿⡿⠃  "⠀
	echo "⠀⠀⠀⠈⠙⠛⠛⠛⠉⠀⠀⠀⠀⠀⠀⠀⠈⠙⠛⠿⠿⠿⠟⠛⠉⠀⠀  "⠀
	echo "         sbelondr            "
}

install_requirement() {
	mkdir -p $DIR_BIN
	if [ ! -f "$KUB" ]; then
		pushd $DIR_BIN
			echo -n "Install kubectl ..."
			curl -LO $URL_BIN_KUB > /dev/null
			curl -LO $URL_SHA_KUB > /dev/null
			out=$(echo "$(cat kubectl.sha256)  kubectl" | sha256sum --check)
			if [ "kubectl: OK" == "$out" ]; then
				sudo install -o root -g root -m 0755 kubectl $KUB > /dev/null
			else
				echo "Error with kubectl install"
				exit 1
			fi
			echo " ✅"
		popd
	fi
	if [ ! -f "$K3D" ]; then
		echo -n "Install k3d ..."
		bash $SCRIPTS/install-k3d.sh > /dev/null
		echo " ✅"
	fi
	if [ ! -f "$HELM" ]; then
		pushd $DIR_BIN
			echo -n "Install helm ..."
			curl -fsSL -o get_helm.sh $URL_SCRIPT_HELM > /dev/null
			chmod 700 get_helm.sh
			./get_helm.sh > /dev/null
			echo " ✅"
		popd
	fi
	rm -rf $DIR_BIN
}

setup_cluster() {
	if [ "" != "$($K3D cluster list | grep $CLUSTER_NAME)" ]; then
		echo -n "Delete cluster ..."
		$K3D cluster delete $CLUSTER_NAME > /dev/null
		echo " ✅"
	fi
	echo -n "Create cluster ...."
	$K3D cluster create \
	  -p "80:80@loadbalancer" \
	  -p "443:443@loadbalancer" \
	  --api-port 6550 --servers $CLUSTER_SERVER \
	  --agents $CLUSTER_AGENT $CLUSTER_NAME --wait > /dev/null
	echo " ✅"
}

install_certmanager() {
	echo -n "Add cert-manager repo ..."
	helm repo add jetstack https://charts.jetstack.io > /dev/null
	echo " ✅"
	echo -n "Update helm repo ..."
	helm repo update > /dev/null
	echo " ✅"

	echo -n "Apply crd ..."
	kubectl apply -f $CONFS/cert-manager.crds.yaml > /dev/null
	echo " ✅"

	echo -n "Setup namespace ..."
	kubectl create namespace $NS_CERT > /dev/null
	kubectl label namespace $NS_CERT certmanager.k8s.io/disable-validation=true > /dev/null
	echo " ✅"

	echo -n "Install cert-manager ..."
	helm install $CERT_NAME \
		--namespace $NS_CERT \
		--version v1.10.0 jetstack/cert-manager \
		--set ingressShim.defaultIssuerName=letsencrypt-prod \
		--set ingressShim.defaultIssuerKind=ClusterIssuer > /dev/null
	echo " ✅"

	echo -n "Wait cert-manager ..."
	kubectl -n $NS_CERT wait --for=condition=available \
		--timeout=9000s deployment.apps/cert-manager > /dev/null
	echo " ✅"

	echo -n "Apply cluster issuer ..."
	$KUB apply -f $CONFS/certmanager/cluster-issuer.yaml > /dev/null
	echo " ✅"
}

install_gitlab() {
	if [ -n "$($HELM list -n $NS_GITLAB | grep $GITLAB_NAME)" ];then
		echo -n "Uninstall gitlab ..."
		$HELM uninstall -n $NS_GITLAB $GITLAB_NAME > /dev/null
		$KUB delete ns $NS_GITLAB > /dev/null
		echo " 🌑"
	fi
	echo -n "Add gitlab repo ..."
	$HELM repo add $GITLAB_NAME https://charts.gitlab.io/ > /dev/null
	echo " 🌒"

	echo -n "Update all helm repo ..."
	$HELM repo update > /dev/null
	echo " 🌓"

	echo -n "Install gitlab..."
	$HELM install $GITLAB_NAME gitlab/gitlab \
	  --timeout 600s \
	  --create-namespace -n $NS_GITLAB \
	  -f $CONFS/values-gitlab.yaml > /dev/null
	echo " 🌔"
	echo -n "Wait gitlab webservice is ready ... "
	kubectl -n $NS_GITLAB wait --for=condition=available \
		--timeout=9000s deployment/gitlab-webservice-default > /dev/null
	echo " 🌕"

	echo -n "Apply ingress setup ..."
	$KUB apply -f $CONFS/certmanager/certmanager-gitlab.askhalog.space.yaml > /dev/null
	sleep 2
	$KUB apply -f $CONFS/certmanager/ingress-gitlab.askhalog.space.yaml > /dev/null
	echo " 🔥"
}

install_argo() {
	echo -n "Create namespace $NS_DEV and $NS_ARGO ..."
	if [ -z "$($KUB get ns | grep $NS_ARGO)" ]; then
		$KUB create ns $NS_ARGO > /dev/null
	fi
	if [ -z "$($KUB get ns | grep $NS_DEV)" ]; then
		$KUB create ns $NS_DEV > /dev/null
	fi
	echo " ✅"
	echo -n "Install argocd ..."
	$KUB apply -f $CONFS/argocd.yaml -n $NS_ARGO > /dev/null
	echo " ✅"
	echo -n "Wait argocd ..."
	kubectl -n $NS_ARGO wait --for=condition=available --timeout=9000s deployment.apps/argocd-server > /dev/null
	echo " ✅"
	echo -n "Add redirection for argocd ..."
	$KUB apply -f $CONFS/certmanager/certmanager-argocd.askhalog.space.yaml > /dev/null
	sleep 2
	$KUB apply -f $CONFS/certmanager/ingress-argocd.askhalog.space.yaml > /dev/null
	echo " ✅"

	echo -n "Edit argocd password ..."
        $KUB -n $NS_ARGO patch secret argocd-secret \
		-p '{"stringData": {
			"admin.password": "$2y$12$Kg4H0rLL/RVrWUVhj6ykeO3Ei/YqbGaqp.jAtzzUSJdYWT6LUh/n6",
			"admin.passwordMtime": "'$(date +%FT%T%Z)'"
		}}' > /dev/null
	echo " ✅"
}

print_info() {
	echo "Argocd:"
	echo -e "\tUser: admin"
	echo -e "\tPassword : mysupersecretpassword"
	echo "Gitlab:"
	echo -e "User: root"
	echo -ne "\tPassword : "
	kubectl get -n $NS_GITLAB secret gitlab-gitlab-initial-root-password \
		-ojsonpath='{.data.password}' | base64 --decode ; echo
}

welcome
install_requirement
setup_cluster
install_certmanager
install_gitlab
install_argo
print_info
