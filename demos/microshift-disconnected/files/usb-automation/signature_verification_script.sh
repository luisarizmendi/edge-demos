#!/bin/bash

# Ensure that a directory path is provided
if [ -z "$1" ]; then
    echo "Error: Directory path not provided."
    exit 1
fi

USB_DIR="$1"

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
