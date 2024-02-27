#!/bin/bash

script_dir="$(dirname "$0")"

oc --kubeconfig /var/lib/microshift/resources/kubeadmin/kubeconfig create -f $script_dir/secrets/secret-http-user.yaml

if [ $? -eq 0 ]; then
    echo "secret-http app configuration successful"
else
    echo "secret-http app configuration failed"
    exit 1
fi

oc --kubeconfig /var/lib/microshift/resources/kubeadmin/kubeconfig create -f $script_dir/secrets/secret-http-password.yaml

if [ $? -eq 0 ]; then
    echo "secret-http app configuration successful"
else
    echo "secret-http app configuration failed"
    exit 1
fi

oc  --kubeconfig /var/lib/microshift/resources/kubeadmin/kubeconfig  -n secret-http rollout restart deployment secret-http
