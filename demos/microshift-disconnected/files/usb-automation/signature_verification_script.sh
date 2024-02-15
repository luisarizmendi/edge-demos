#!/bin/bash

TEMP_DIR="/tmp/usb-automation"

# Ensure that a directory path is provided
if [ -z "$1" ]; then
    echo "Error: USB device not provided."
    exit 1
fi

USB_DEVICE="$1"

if [ -z "$2" ]; then
    echo "Error: Directory path to be checked not provided."
    exit 1
fi

RHDE_DIR="$2"






echo Device connected: $USB_DEVICE
mkdir -p $TEMP_DIR
mount $USB_DEVICE $TEMP_DIR

echo Contents of $USB_DEVICE
echo $(ls $TEMP_DIR)

# Check if the rhde directory exists on the USB device
if [ -d "${TEMP_DIR}/${RHDE_DIR}" ]; then
    echo "Directory ${TEMP_DIR}/${RHDE_DIR} exist!"
else
    echo "Directory ${TEMP_DIR}/${RHDE_DIR} not found."
    umount $TEMP_DIR
    exit 1
fi







umount $TEMP_DIR



















# Verify the digital signature of the rhde directory
gpg --verify "$USB_DIR/rhde.sig" "$USB_DIR/rhde"
verification_status=$?

if [ $verification_status -eq 0 ]; then
    # Signature verification successful
    echo "Digital signature verification successful."
    
    # Proceed with further actions (e.g., copying files, running scripts)
    # Example: Copy rhde directory to /tmp/rhde-automation
    cp -r "$USB_DIR" /tmp/rhde-automation
    
    # Example: Check if rhde.sh exists and execute it with root privileges
    if [ -f "/tmp/rhde-automation/rhde.sh" ]; then
        sudo /bin/bash "/tmp/rhde-automation/rhde.sh"
    fi
else
    # Signature verification failed
    echo "Error: Digital signature verification failed."
    exit 1
fi
