# RHDE management with AAP Demo

## Background

This demo is a new way of deploying the same components that you can find in [this Red Hat Device Edge GitOps demo](https://github.com/redhat-manufacturing/device-edge-workshops/blob/gitops-demo/exercises/rhde_gitops/demo/README.md) but making it easier and faster to deploy, by using the [rh_edge_mgmt Ansble collection](https://github.com/luisarizmendi/rh_edge_mgmt) that was developed for such propose.

It does not contain all the playbooks that you might find in [this Red Hat Device Edge GitOps demo](https://github.com/redhat-manufacturing/device-edge-workshops/blob/gitops-demo/exercises/rhde_gitops/demo/README.md) because the idea was not to recreate it completely, but giving enough pieces to make the demo easy to extend and customize.

The explanation of the demo steps is not as extensive as what you can find in the original [Red Hat Device Edge GitOps demo](https://github.com/redhat-manufacturing/device-edge-workshops/blob/gitops-demo/exercises/rhde_gitops/demo/README.md) so if you have any doubt you probably will find the answer.

For this demo, the script creates a VM on AWS, installs the required services and then configures them.

## Overview of the workflow

First you need to deploy the services, which implies two things:

* Create the VM
* Install and configure the services

For the first point, I provide a Terraform script to create a RHEL VM on AWS. Then the Ansible collection will be used to install and configure the management services on top of it.

The demo deployment will use two Ansible roles part of a collection:

1) [setup_rh_edge_mgmt_node role](https://github.com/luisarizmendi/rh_edge_mgmt/tree/main/roles/setup_rh_edge_mgmt_node) will deploy the different management services

2) [config_rh_edge_mgmt_node role](https://github.com/luisarizmendi/rh_edge_mgmt/tree/main/roles/config_rh_edge_mgmt_node) will configure those services using the variables contained in the `templates` folder (you can read the [role README file](https://github.com/luisarizmendi/rh_edge_mgmt/tree/main/roles/config_rh_edge_mgmt_node) if you want more information)


After the deployment you will use one of the configured users to:

* Modify the RHDE image description (ie. adding the `bind-utils` package)
* Check that an Ansible Workflow automatically starts and build the new image
* Accept the image publishing in that Workflow once the image is created
* Create an ISO to deploy the image
* Deploy the image in the edge device
* Check that the device is auto-registered in AAP and correctly onboarded (in this base demo it is just a change in the hostname)


## Pre-requisites


### VM creation with Terraform

You will need to:

* Install Terraform in your laptop

* Prepare your AWS credentials in `~/.aws/credentials`

```
[default]
aws_access_key_id = your_access_key_id
aws_secret_access_key = your_secret_access_key
```

+ Prepare Terraform variables in file `terraform/rhel_vm.tfvars`


### Ansible Collection

You need to install the [Ansible Collection](https://github.com/luisarizmendi/rh_edge_mgmt) on your laptop:

```shell
ansible-galaxy collection install luisarizmendi.rh_edge_mgmt
```

### Hardware requirements

At least two devices/VMs:

* Edge Management node: I've been able to deploy everything on a VM with 4 vCores and 10GB of memory. Storage will depend on the number of RHDE images that you generate.

* Edge Device: This will depend on what you install on top, but for the base deployment you can use 1.5 vCores, 3GB of memory and 50GB disk.


### Roles pre-requisites

This is the summary of the pre-requisites (all for installing the services):

* Ansible Automation Platform Manifest file
* Red Hat Customer Portal Offline Token
* Red Hat Pull Secret
* Red Hat User and Password

You can find more details about them in the role README file:

* [setup_rh_edge_mgmt_node role](https://github.com/luisarizmendi/rh_edge_mgmt/tree/main/roles/setup_rh_edge_mgmt_node)

You can also take a look at the pre-requistes of the config role, but mainly is demo config customization, you could deploy using the default values.

* [config_rh_edge_mgmt_node role](https://github.com/luisarizmendi/rh_edge_mgmt/tree/main/roles/config_rh_edge_mgmt_node)

  >**Note**
  >
  > You can ignore the additional Collections installation since those should be installed as part of the `luisarizmendi.rh_edge_mgmt` collection install.



### Ansible inventory and variables

Prepare the Ansible inventory file and the variables in the `main.yml` playbook as explained in the roles README files.

  >**Note**
  >
  > If you are using the directory tree of this example you could keep the variables that you find there (`gitea_admin_repos_template`, `aap_config_template`, ...), but probably you will need to configure the `image_builder_admin_name` and `image_builder_admin_password` with the user with `sudo` privileges in the RHEL server where you installed the Image Builder.


## DEMO deployment

Once you have all the pre-requisites ready, including the Ansible Vault secret file, you need to:

1) Run Terraform to create the VM

```shell
cd terraform
terraform init -var-file="rhel_vm.tfvars"
terraform apply  -var-file="rhel_vm.tfvars"
cd ..
```

2) run the main playbook including the Vault password by adding the `--ask-vault-pass` option:

```shell
cd ansible
ansible-playbook -vvi inventory --ask-vault-pass playbooks/main.yml
cd ..
```

The deployment will take some time, depending on the edge management device/VM.

I've also created a shell script that you can use if you don't want to perform those steps manually, in that case you just need to run:

```shell
./deploy.sh
```

## DEMO steps

### 1 - Modify the RHDE image description

* Go to Gitea in the edge management host at port `3000`
* Log in as a user (by default `user<number>`/`password<number>`)
* Modify the file in `rhde/prod/rhde_image/production-image-definition.yml`. You can include the `bind-utils` package

### 2 - Check that an Ansible Workflow automatically starts and build the new image

* Log in the AAP Controller (port `8443`) as a regular user (by default `user<number>`/`password<number>`)
* Check the "Jobs" view and see if a new Workflow has started

### 3 - Accept the image publishing in that Workflow once the image is created

* Wait until the image is created, you can check the progress by using Cockpit (port `9090`)
* Approve the image publishing in the Workflow

### 4 - Create an ISO to deploy the image

* Launch the `Create ISO Kickstart` task under "Templates" view in AAP Controller. Default variables should be ok unless you are not using default values for this demo
* Download the ISO from the URL shown in the last `debug` message that you will find in the `Create ISO Kickstart` task output (maybe you need to "Reload output" when the task is done to see the debug message at the end)

  >**Note**
  >
  > If you create/publish new versions of your image for your demo, you don't need to create additional ISO images, you will be able to re-use the same ISO while the environment (`prod`) or the image name changes.


### 5 - Deploy the image in the edge device

* Start the edge device from the ISO that you downloaded (using an USB if it's a physical device).Be sure that you are using Legacy BIOS boot since the generated ISO is prepared for that one.
* Wait until the deployment finishes. Then the device will reboot and use the local drive as first boot option
* Wait a little bit until you see in AAP Controller a new Workflow execution (`Provision Edge Device` Workflow)


### 6 - Check that the device is auto-registered in AAP and correctly onboarded (in this base demo it is just a change in the hostname)

* Log into the edge deivice (you can check the IP in the AAP inventory)
* Check that the hostname was changed and a new entry configured in `/etc/hosts`
* You can also take a look at the Event Driven Automation Controller (port `8445`, credentials `admin`/`R3dh4t1!` if not customized during the deployment) to check out how the request were processed.



## DEMO customization

The easier way to customize the demo is to include additional "Templates" in the AAP Controller and add them in the `Provision Edge Device` Workflow, so the device will be auto-customized during the first run. You can also take some ideas from the original [Red Hat Device Edge GitOps demo](https://github.com/redhat-manufacturing/device-edge-workshops/blob/gitops-demo/exercises/rhde_gitops/demo/README.md) demo steps.
