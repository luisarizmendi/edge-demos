#!/bin/bash

oc --kubeconfig /var/lib/microshift/resources/kubeadmin/kubeconfig create -f secrets/secret-http.yaml

if [ $? -eq 0 ]; then
    echo "secret-http app configuration successful"
    exit 0
else
    echo "secret-http app configuration failed"
    exit 1
fi

oc  --kubeconfig /var/lib/microshift/resources/kubeadmin/kubeconfig  -n secret-http rollout restart deployment secret-http
