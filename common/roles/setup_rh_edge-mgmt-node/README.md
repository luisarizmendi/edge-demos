# setup_edge-mgmt-node role

This Ansible Role was created to be used as a simple way of deploying all Management components that you would need to run a Red Hat Edge Management DEMO:

* Image Builder
* FDO Servers
* Ansible Automation Platform (Controller, Hub and Event Driven Automation)
* Gitea

## Pre-requisites

### Ansible Collections

You need to have a couple of Collections installed on your laptop:

```bash
ansible-galaxy collection install -f git+https://github.com/redhat-cop/infra.osbuild --upgrade
ansible-galaxy collection install -f containers.podman --upgrade
```

### Ansible Automation Platform Manifest

In order to use Automation controller you need to have a valid subscription via a `manifest.zip` file. To retrieve your manifest.zip file you need to download it from access.redhat.com.

You have the steps in the [Ansible Platform Documentation](https://access.redhat.com/documentation/en-us/red_hat_ansible_automation_platform/2.4/html/red_hat_ansible_automation_platform_operations_guide/assembly-aap-obtain-manifest-files)

1. Go to [Subscription Allocation](https://access.redhat.com/management/subscription_allocations) and click "New Subscription Allocation"

2. Enter a name for the allocation and select `Satellite 6.8` as "Type".

3. Add the subscription entitlements needed (click the tab and click "Add Subscriptions") where Ansible Automation Platform is available.

4. Go back to "Details" tab and click "Export Manifest" 

Save apart your `manifest.zip` file (location configured with the `manifest_file` variable or in `../files/manifest.zip` by default).

  >**Note**
  >
  > If you want to check the contents of the ZIP file you will see a `consumer_export.zip` file and a `signature` inside.


### Red Hat Customer Portal Offline Token

This token is used to authenticate to the customer portal and download software. It is needed to deploy the Ansible Automation Platform server.

It can be generated [here](https://access.redhat.com/management/api).

  >**Note**
  >
  >  Remember that the Offline tokens will expire after 30 days of inactivity. If your offline Token is not valid, you won't be able to download the `aap.tar.gz`. 

Take note of the token.


### Red Hat Pull Secret

This Pull Secret will be needed to pull the container images used by `Microshift` from the Red Hat's container repository.  It is needed to deploy the Ansible Automation Platform server.

[Get your pull secret from the Red Hat Console](https://cloud.redhat.com/openshift/install/pull-secret)



## Role Usage

### Create Vault Secret file

In order to now passing your secrets in plain test, you should create a vault secrets file:

```bash
mkdir vars
ansible-vault create vars/secrets.yml
```

  >**Note**
  >
  >  Remember the password that you used to encrypt the file, since it will be needed to access the contents

Include the following information:

```yaml
pull_secret: '<your pull secret>'
offline_token: '<your offline token>'
red_hat_user: <your RHN user>
red_hat_password: <your RHN password>
```


### Create a Playbook that uses the role

Create a playbook that will launch the role:

```bash
mkdir playbooks
vi playbooks/main.yml
```


Use a task to call the role, as it appears in the example below:


```yaml
- name: RHDE and AAP Demo
  hosts:
    - edge_management
  tasks:
    - name: Install management node
      ansible.builtin.include_role:
        name: ../../../../common/roles/setup_edge-mgmt-node
```

By default the role deploys all services. If you want to remove any of them, or if you need to customize your servers you can add the variables that you want to change from the [role defaults](defaults/main.yml), for example, if you don't want to deploy the FDO servers:

```yaml
- name: RHDE and AAP Demo
  hosts:
    - edge_management
  tasks:
    - name: Install management node
      ansible.builtin.include_role:
        name: ../../../../common/roles/setup_edge-mgmt-node
      vars:
        include_fdo: false
```


### Prepare the required files

As mentioned durnig the pre-requisites section, the role uses the `manifest.zip` file to deploy. If you don't customize the location with the `manifest_file` variable, you will need to copy the `manifest.zip` into the `files` directory:


```bash
mkdir files
cp <your manifest.zip file> files/manifest.zip
```



### Create the Ansible inventory

Create an inventory file.

```bash
vi inventory
```

This is an example of the contents of that file:

```yaml
all:
  hosts:
    edge_management:
      ansible_host: 192.168.122.79
      ansible_port: 22
      ansible_user: admin
```



### Launch the playbook using the Vault Secrets

Launch the playbook using the Vault Secret file:

```bash
ansible-playbook -vvi inventory --ask-vault-pass playbooks/main.yml
```


### Access the services

Once the role finish (you might need to wait a little bit after the role completion), you will be able to access the service in these ports (if you didn't customize them):

* Ansible Automation Platform Controller: 8080 (HTTP) / 8443 (HTTPS)
* Ansible Automation Platform Hub:  8081 (HTTP) / 8444 (HTTPS)
* Ansible Automation Platform Event-Driven Ansible Controller:  8082 (HTTP) / 8445 (HTTPS)
* Cockpit: 9090
* Gitea: 3000
* FDO Manufacturing server: 18080
* FDO Redezvous server: 18082
* FDO Owner server: 18081
* FDO Service Info server: 18083



