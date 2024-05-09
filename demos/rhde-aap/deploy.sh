#!/bin/bash

# variables
TF_SCRIPT="rhel_vm.tf"
TF_VARS="rhel_vm.tfvars"
TF_STATE="terraform.tfstate"
TF_LOG="terraform.log"
VM_READY=false



echo "Introduce your Ansible Vault Secret:"
read -s -p "Enter vault secret: " VAULT_SECRET
echo


############################
####### CREATE THE VM IN AWS
############################



# Run Terraform

cd terraform

terraform init -input=false -backend=false -reconfigure -lock=false -force-copy -var-file="${TF_VARS}" > "${TF_LOG}"

terraform apply -input=false -auto-approve -var-file="${TF_VARS}" > "${TF_LOG}"

# Retrieve public IP of the created VM
VM_IP=$(terraform output -state="${TF_STATE}" public_ip  | sed 's/"//g')

while ! ssh -o BatchMode=yes -o ConnectTimeout=10 -o StrictHostKeyChecking=no ec2-user@${VM_IP} 'exit' &>/dev/null; do
    echo "Waiting for SSH to IP ${VM_IP}..."
    sleep 60
done

echo "SSH is accessible. VM is ready."
cd ..

############################
####### INSTALL DEMO
############################

cd ansible


echo "Adding IP to the inventory"
sed -i "s/ansible_host: .*/ansible_host: ${VM_IP}/" inventory

echo "Running Ansible playbooks"

ansible-playbook -vvi inventory --vault-password-file <(echo "$VAULT_SECRET") playbooks/main.yml


echo ""
echo "###############################################"
echo ""
echo "YOU CAN CONNECT TO THE FOLLOWING SERVICES:"
echo "     + AAP Controller: https://${VM_IP}:8443"
echo "     + AAP Hub: https://${VM_IP}:8444"
echo "     + EDA: https://${VM_IP}:8445"
echo "     + Gitea: http://${VM_IP}:3000"
echo "     + Cockpit: https://${VM_IP}:9090"
echo ""
echo "###############################################"
echo ""
echo ""
