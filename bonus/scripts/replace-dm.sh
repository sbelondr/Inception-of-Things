#!/bin/bash

OLD_DM_argo="[MY_ARGO_DOMAIN]"
NEW_DM_argo=""

OLD_DM_git="[MY_GIT_DOMAIN]"
NEW_DM_git=""

OLD_MAIL="[MY_MAIL]"
NEW_MAIL=""

replace_dm() {
	sed -i "s/$OLD_DM_argo/$NEW_DM_argo/g" $1
	sed -i "s/$OLD_DM_git/$NEW_DM_git/g" $1
}

replace_dm ./confs/values-gitlab.yaml

replace_dm ./confs/certmanager/certmanager-gitlab.askhalog.space.yaml
replace_dm ./confs/certmanager/certmanager-argocd.askhalog.space.yaml

replace_dm ./confs/certmanager/ingress-gitlab.askhalog.space.yaml
replace_dm ./confs/certmanager/ingress-argocd.askhalog.space.yaml

sed -i "s/$OLD_MAIL/$NEW_MAIL/g" ./confs/certmanager/cluster-issuer.yaml
