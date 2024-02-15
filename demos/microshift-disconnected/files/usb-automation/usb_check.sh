#!/bin/bash


# Get the device path of the last USB device connected
usb_device_path=$(udevadm info --query=path --name=$(lsblk -no pkname "$(lsblk -Sdrpo "TYPE='disk'")" | tail -n 1))

# Extract the device name from the device path
usb_device_name=$(basename "$usb_device_path")

# Echo the device name
echo "Last USB device connected: $usb_device_name"







# Ensure that a USB device path is provided
if [ -z "$USB_DEVICE_PATH" ]; then
    exit 1
fi

RHDE_DIR="$USB_DEVICE/rhde"

# Check if the rhde directory exists on the USB device
if [ -d "$RHDE_DIR" ]; then
    # Trigger another script to verify the digital signature and perform further actions
    /usr/local/bin/signature_verification_script.sh "$RHDE_DIR"
fi