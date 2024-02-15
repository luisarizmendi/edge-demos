#!/bin/bash

# Log file path
log_file="/var/log/usb_check.log"

# Redirect stdout and stderr to the log file
exec > "$log_file" 2>&1

# Ensure that a USB device path is provided
if [ -z "$1" ]; then
    exit 1
fi

USB_DEVICE="$1"
RHDE_DIR="rhde"


/usr/local/bin/signature_verification_script.sh $USB_DEVICE $RHDE_DIR