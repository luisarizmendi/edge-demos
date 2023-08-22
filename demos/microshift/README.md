# OSTree system and podman-managed APPs lifecycle demo

## Background 

TBD


In this demo, we will explore:

* TBD 


References:
- [Red Hat official documentation for Microshift](https://access.redhat.com/documentation/en-us/red_hat_build_of_microshift/4.13)
- [Red Hat official documentation for RHEL OSTree](https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/9/html-single/composing_installing_and_managing_rhel_for_edge_images/index)
- [Red Hat Device Edge introduction](https://cloud.redhat.com/blog/introducing-the-new-red-hat-device-edge)
- (Red Hat internal) [Red Hat Device Edge slide deck](https://docs.google.com/presentation/d/1FKQDHrleCPuE0e36UekzXdkw86wNDx16dSgllXj-swY/edit?usp=sharing)
- [OSTree based Operating Systems article](https://luis-javier-arizmendi-alonso.medium.com/a-git-like-linux-operating-system-d84211e97933)
- [Image Builder quickstart bash scripts](https://github.com/luisarizmendi/rhel-edge-quickstart)
- [Ansible Collection for OSTree image management](https://github.com/redhat-cop/infra.osbuild)
- [Ansible Collection for Microshift management](https://github.com/redhat-cop/edge.microshift)

<br><br>

<hr style="border:2px solid gray">

## Pre-requisites
<hr style="border:2px solid gray">

You could use baremetal servers for this demo but you can run it too with just a couple of VMs running on your laptop (Image Builder and edge device).

You need an active Red Hat Enterprise Linux subscription.

<br><br>

<hr style="border:2px solid gray">

## Demo preparation

<hr style="border:2px solid gray">


BEFORE delivering the demo, you have to complete these preparation steps.

### Preparing the Image Builder

You need a subscribed [Red Hat Enterprise Linux 9](https://access.redhat.com/downloads/content/479/ver=/rhel---9/9.1/x86_64/product-software) system (minimal install is enough) with at least 2 vCPUs, 4 GB memory and 50 GB disk.

If you don't want to use `root`, be sure that the user has [passwordless sudo access](https://developers.redhat.com/blog/2018/08/15/how-to-enable-sudo-on-rhel).


### Preparing your laptop

Your will need to:

* Install Ansible

> laptop
```
dnf install -y ansible
```

* Download the `infra.osbuild` and `edge.microshift` Ansible collections

> laptop
```
ansible-galaxy collection install -f git+https://github.com/redhat-cop/infra.osbuild --upgrade
ansible-galaxy collection install -f git+https://github.com/redhat-cop/edge.microshift --upgrade

```

* Modify the Ansible `inventory` file with your values

* Copy your public SSH key into the Image Builder system, so you can open passwordless SSH sessions with the user that you configured in your Ansible inventory. (double check .ssh and authorized_keys permissions in case you are still asked for password after copying the key).

> laptop
```
ssh-copy-id <user>@<image builder IP>
```

* If you are using your laptop as hypervisor, be sure that you have at least 2 vCPU, 1.5GB memory and 20 GB disk free to create the Edge device VM (in addition the Image Builder VM that you should have already up and running).



### Preparing the OSTree images

You will need to prepare the Microshift image before running the demo since it takes some time to complete.

As part of the image preparation, you will be injecting your **pull secret** as an Ansible variable. Although you could just create a plain variable in vars/main.yaml it's highly recomended to encrypt sensitive infomation, so it's better to [Ansible Vault](https://docs.ansible.com/ansible/latest/vault_guide/index.html) by creating the encrypted variable file (protected by a password that you configure) using the following command:

> laptop
```
ansible-vault create vars/secrets.yml
```

**_NOTE:_** *Remember to include `--ask-vault-pass` when you try to run your Ansible playbooks containing Ansible Vault encrypted files*


By default a test app will be deployed along with microshift. If you want to skip that step just comment out the `microshift_test_app_template` line in cars/main.yaml.



Run the following Ansible Playbook:

> laptop
```
ansible-playbook -vvi inventory --ask-vault-pass playbooks/00-preparation-ostree.yml
```

It will:
* Install Image Builder
* Create the OSTree Image with Microshift

Once the Ansible Playbook is finished, you will see the URL where the ISO is published in the last Ansible `debug` message. Download it to the system where you will create the Edge device VM.


<br><br>

<hr style="border:2px solid gray">

## Demo steps

<hr style="border:2px solid gray">

TBD

<br>
<br>

### Step 0 - xxxxxxxxxxxxxxxxxxxx

---
**Summary**

TBD

---

TBD




### BONUS - Serverless service with Podman
---
**Summary**

TBD






