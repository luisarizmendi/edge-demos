#!/bin/bash

# Log file path
log_file="/var/log/usb_check.log"

# Redirect stdout and stderr to the log file
exec > "$log_file" 2>&1

sleep 3

############### VARS ####################

RHDE_DIR="rhde"
RHDE_AUTOMATION_DIR="rhde-automation"
RHDE_AUTOMATION_TAR="rhde-automation.tar.gz"
RHDE_AUTOMATION_RUN="/usr/local/bin/rhde_automation_run.sh"

TEMP_DIR="/tmp/usb-autoconfigure"

SIGNATURE_VERIFICATION_SCRIPT="/usr/local/bin/signature_verification_script.sh"

USB_DEVICE=$(cat /tmp/last-usb)

SIGNATURE_FILE="rhde-automation-signature.sha256"
PUBLIC_KEY="/root/rhde-automation-pub.pem"

######################################


mkdir -p $TEMP_DIR

echo "Mounting ${USB_DEVICE}1 into ${TEMP_DIR}"
# Mount the filesystem using systemd-mount
mount ${USB_DEVICE}1 ${TEMP_DIR}

# Check if the mount was successful
if [ $? -eq 0 ]; then
    echo "Mount successful"
else
    echo "Mount failed"
    exit 1
fi




# Check if the rhde directory exists on the USB device
if [ -d "${TEMP_DIR}/${RHDE_DIR}" ]; then
    echo "Directory ${TEMP_DIR}/${RHDE_DIR} exist!"

    chmod +x ${SIGNATURE_VERIFICATION_SCRIPT}
    ## script <dir> <signature file> <public key>
    ${SIGNATURE_VERIFICATION_SCRIPT} ${TEMP_DIR}/${RHDE_DIR}/${RHDE_AUTOMATION_TAR} ${TEMP_DIR}/${RHDE_DIR}/${SIGNATURE_FILE} ${PUBLIC_KEY}

    if [ $? -eq 0 ]; then
        echo "Signature verification succeded"
       
       # script <tar location> <directory in the tar with the scripts> 
        ${RHDE_AUTOMATION_RUN} ${TEMP_DIR}/${RHDE_DIR}/${RHDE_AUTOMATION_TAR} ${RHDE_AUTOMATION_DIR}

        # Check if the automation script was successful
        if [ $? -eq 0 ]; then
            echo "Automation successful"
        else
            echo "Automation failed"
            exit 4
        fi


    else
        echo "Error: Signature verification failed"
        umount $TEMP_DIR
        exit 3
    fi


    

else
    echo "Directory ${TEMP_DIR}/${RHDE_DIR} not found."
    umount $TEMP_DIR
    exit 2
fi



# Unmount the filesystem using systemd-umount
umount ${TEMP_DIR}

# Check if the umount was successful
if [ $? -eq 0 ]; then
    echo "Unmount successful"
else
    echo "Unmount failed"
    exit 1
fi

exit 0