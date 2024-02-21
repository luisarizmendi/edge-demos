#!/bin/bash

## CHECK VARS


##################

SCRIPTS_TAR_FILE=$1
SCRIPTS_DIR=$2

SCRIPTS_TEMP_DIR="/tmp/rhde-automation-scripts"



echo "Creating directory ${SCRIPTS_TEMP_DIR}"
mkdir -p ${SCRIPTS_TEMP_DIR}




echo "Decompressing file ${SCRIPTS_TAR_FILE}"
tar zxvf ${SCRIPTS_TAR_FILE} -C ${SCRIPTS_TEMP_DIR}

for i in $(ls ${SCRIPTS_TEMP_DIR}/${SCRIPTS_DIR}/* | grep \.sh$)
do 
        chmod +x $i 
        echo "Running script ${SCRIPTS_TEMP_DIR}/${SCRIPTS_DIR}/$1 ..."
        $i 
        # Check if the script was successful
        if [ $? -eq 0 ]; then
                echo "Script $i successful"
        else
                echo "ERROR: Script $1 failed"
                exit 1
        fi

done



echo "Removing directory ${SCRIPTS_TEMP_DIR}"
rm -rf ${SCRIPTS_TEMP_DIR}


exit 0
