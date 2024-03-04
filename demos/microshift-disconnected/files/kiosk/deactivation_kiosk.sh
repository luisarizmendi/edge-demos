#!/bin/bash

activation_file="/var/tmp/activation_done"

perform_actions() {

    sleep 5 
    
    systemctl isolate multi-user.target
    systemctl stop gdm.service

    systemctl disable deactivation-kiosk.service    
}

while [ ! -f "$activation_file" ]; do
    sleep 5
done

perform_actions