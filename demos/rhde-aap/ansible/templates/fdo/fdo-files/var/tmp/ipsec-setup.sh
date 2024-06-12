#!/bin/bash

set -x

if rpm -q libreswan &> /dev/null; then

    copy /var/opt/ipsec.secrets /etc/ipsec.secrets

    systemctl enable ipsec
    systemctl start ipsec 
fi
