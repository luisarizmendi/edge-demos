# Microshift embedded images sandbox

## Background 

This "demo" is a little bit special, since I won't include any demo steps. This could be re-named as a Microshift embedded images sandbox since this repo will give you the bit to deploy Microshift in a disconnected environment easily in a VM in your laptop without the need even of a public DNS name (by default it is using [nip.io](nip.io) ).  


References:
- [Red Hat official documentation for Microshift](https://access.redhat.com/documentation/en-us/red_hat_build_of_microshift/4.13)
- [Red Hat official documentation for RHEL OSTree](https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/9/html-single/composing_installing_and_managing_rhel_for_edge_images/index)
- [Red Hat Device Edge introduction](https://cloud.redhat.com/blog/introducing-the-new-red-hat-device-edge)
- (Red Hat internal) [Red Hat Device Edge slide deck](https://docs.google.com/presentation/d/1FKQDHrleCPuE0e36UekzXdkw86wNDx16dSgllXj-swY/edit?usp=sharing)
- [OSTree based Operating Systems article](https://luis-javier-arizmendi-alonso.medium.com/a-git-like-linux-operating-system-d84211e97933)
- [Image Builder quickstart bash scripts](https://github.com/luisarizmendi/rhel-edge-quickstart)
- [Ansible Collection for OSTree image management](https://github.com/redhat-cop/infra.osbuild)

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


<br><br>

### ~ ~ ~ ~ Preparing the Image Builder ~ ~ ~ ~

You need a subscribed [Red Hat Enterprise Linux 9](https://access.redhat.com/downloads/content/479/ver=/rhel---9/9.3/x86_64/product-software) system (minimal install is enough) with at least 2 vCPUs, 4 GB memory and 50 GB disk.

If you don't want to use `root`, be sure that the user has [passwordless sudo access](https://developers.redhat.com/blog/2018/08/15/how-to-enable-sudo-on-rhel).


<br><br>

### ~ ~ ~ ~ Preparing your laptop ~ ~ ~ ~

Your will need to:

* Install Ansible

> laptop
```
dnf install -y ansible
```

* Download the `infra.osbuild`  Ansible collection. Since the collection is still not able to get the embedded images as a parameter I created a pull request to allow including customized blueprints: https://github.com/redhat-cop/infra.osbuild/pull/347

The PR is not approved yet so you will need to use my local fork until it's included into the official collection:

> laptop
```
ansible-galaxy collection install -f git+https://github.com/luisarizmendi/infra.osbuild?ref=import_blueprint --upgrade

```

* Modify the Ansible `inventory` file with your values


* Modify the Ansible `vars/main.yml` file with your values. You might want to change the `microshift_release` or, if you want to manually create the blueprint file with the embedded images instead of let the playbooks to do it, you could switch `microshift_embedded_generate_blueprint` to false and create your own `files/blueprint-microshift-embedded.toml` file.

* Copy your public SSH key into the Image Builder system, so you can open passwordless SSH sessions with the user that you configured in your Ansible inventory. (double check .ssh and authorized_keys permissions in case you are still asked for password after copying the key).

> laptop
```
ssh-copy-id <user>@<image builder IP>
```

* If you are using your laptop as hypervisor, be sure that you have at least 2 vCPU, 1.5GB memory and 20 GB disk free to create the Edge device VM (in addition the Image Builder VM that you should have already up and running).


<br><br>

### ~ ~ ~ ~ Creating the OSTree image ISO ~ ~ ~ ~

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
ansible-playbook -vvi inventory --ask-vault-pass playbooks/main.yml
```

It will:
* Install Image Builder
* Prepare the image builder to create Microshift offline images
* Create the OSTree Image with Microshift and the corresponding ISO
* Download the ISO to the path configured in `microshift_iso_dst` var

Once the Ansible Playbook is finished, you might need to move the ISO to the right path where the hypervisor can use it, or to the system where you will create the Edge device VM if it's not your laptop.



<br><br>

### ~ ~ ~ ~ Preparing the edge device ~ ~ ~ ~

In order to deploy the Edge Device, follow these steps:

1. Create a VM that will be the Edge Device (if you are not using a baremetal machine) with at least 2 vCPU, 2'5GB memory, 20GB disk and one NIC in a network from where it has access to the Image Builder.

2. Use the ISO downloaded from the Image Builder to install the system (you can get the URL where it is published in the last Ansible debug message from the previous step). Just be sure that the system is starting from the ISO, everything is automatic.

3. Customize your VM to use UEFI boot instead of legacy BIOS. Also probably you want to attach an isolated network to your VM to test the Microshift offline deployment.

4. Wait until the system prompt.


Once the deployment finished you can get the system IP and:

**_NOTE:_** *Depending on your Internet connection, downloading the images could take some time.*

* Connect to the system by SSH using the user configured in the Blueprint (`admin`). You shouldn't need password if you used the same laptop from where you ran the demo preparation since the SSH public key was injected into the OSTree image, otherwise you can use the password configured in the Blueprint (`R3dh4t1!`).
* Get the `kubeconfig` file using the root user (`sudo cat ...`) located in one of the directories located in `/var/lib/microshift/resources/kubeadmin/`. If you didn't changed the Ansible variable defaults, Microshift will be using a [nip.io](nip.io) so probably you will find it in `/var/lib/microshift/resources/kubeadmin/microshift.<ip>.nip.io/kubeconfig`
* Use that kubeconfig file from your laptop and check that you can reach the kubernetes API (ie. with `oc --kubeconfig <kubeconfig file> get namespaces`)  
* If you keep the default Ansible variables, you will find a test application already deployed at `http://test.apps.<ip>.nip.io`




<br><br>

<hr style="border:2px solid gray">

## Demo steps

<hr style="border:2px solid gray">

I didn't created an specific demo steps for microshift (yet?, let me know if you think that could be useful), as I mentioned this repo is intended to be used as a sandbox to create and test whatever you want in Microshift.

You can review the demo application that you have running since it configures Persisten Volumes and Routes too. If you want to test another example, move to the next section.

<br>
<br>


