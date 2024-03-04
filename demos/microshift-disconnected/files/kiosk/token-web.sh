#!/bin/bash

HOST_IP=$(ip addr show $(ip link | grep DEFAULT | grep -v 'ovn\|br\|cni\|ovs\|lo' | awk '{print $2}' | tr -d ':') | grep -oP 'inet \K[\d.]+')
export HOST_IP

echo "Detected Host IP: $HOST_IP"

/usr/bin/podman run --security-opt label:disable --env HOST_IP="$HOST_IP" --env PYTHONUNBUFFERED=1 -v /var/tmp/:/var/tmp/ -v /usr/share:/usr/share -v /var/lib/microshift/resources/kubeadmin:/var/lib/microshift/resources/kubeadmin -p 8080:8080 quay.io/luisarizmendi/kiosk-token:latest
