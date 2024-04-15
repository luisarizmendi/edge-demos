# config_rh_edge-mgmt-node role

This Ansible Role was created to be used as a simple way of configuring the following components that you would need to run a Red Hat Edge Management DEMO:

* Ansible Automation Platform (Controller and Event Driven Automation)
* Gitea

## Pre-requisites

### Ansible Collections

You need to have a couple of Collections installed on your laptop:

```bash
ansible-galaxy collection install -f redhat_cop.controller_configuration --upgrade
ansible-galaxy collection install -f infra.eda_configuration --upgrade
```




