#!/bin/sh

# add index
/usr/local/bin/kubectl create configmap app1-index-html-configmap --from-file=app1/index.html
/usr/local/bin/kubectl create configmap app2-index-html-configmap --from-file=app2/index.html
/usr/local/bin/kubectl create configmap app3-index-html-configmap --from-file=app3/index.html

# add logo
/usr/local/bin/kubectl create configmap nginx-kube-logo-configmap --from-file=kube-logo.svg
