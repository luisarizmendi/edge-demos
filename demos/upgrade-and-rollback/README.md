# OSTree system and podman-managed APPs lifecycle demo

## Background 

When you deploy a system in an Edge location you need to be sure that the lifecycle management must be simplified as much as possible, for example, sometimes you cannot even rely on any specialized person who can troubleshoot the system on site in case of any error.

This implies that you need to be sure that you have an easy way to rollback your APPs or the Operating System without any manual step to a previously known state where the device was working.

You can build this kind of "rollback system" in many ways, but luckily, if you are using RHEL based on OSTree images and Podman to run your containerized APPs you won't need to use any additional tool, since they provide the tools to perform automatic rollback for both the Operating System and the applications when there are problems during an upgrade.


In this demo, we will explore:

* How OSTree RHEL can be easily upgraded and, in case that the upgrade fails or it makes your applications not working as expected, how the Greenboot auto-healing feature, automatically rollbacks to the previous state.

* How Podman can update the containerized APP automatically when a new APP version is published in the registry, and how it automatically rollbacks to the previous version if the new one does not work

Additionally, there is an additional section that includes an "offtopic" use case that can be shown if you have time during the demo (no questions from audience?): Running Serverless services just with RHEL and Podman.


References:
- [Red Hat official documentation for RHEL OSTree](https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/9/html-single/composing_installing_and_managing_rhel_for_edge_images/index)
- [Red Hat Device Edge introduction](https://cloud.redhat.com/blog/introducing-the-new-red-hat-device-edge)
- (Red Hat internal) [Red Hat Device Edge slide deck](https://docs.google.com/presentation/d/1FKQDHrleCPuE0e36UekzXdkw86wNDx16dSgllXj-swY/edit?usp=sharing)
- [OSTree based Operating Systems article](https://luis-javier-arizmendi-alonso.medium.com/a-git-like-linux-operating-system-d84211e97933)
- [Image Builder quickstart bash scripts](https://github.com/luisarizmendi/rhel-edge-quickstart)
- [Ansible Collection for OSTree image management](https://github.com/redhat-cop/infra.osbuild)
- [Article about Podman root-less containers](https://developers.redhat.com/blog/2020/09/25/rootless-containers-with-podman-the-basics)
- [Article about implementing Serverless services with Podman](https://www.redhat.com/en/blog/painless-services-implementing-serverless-rootless-podman-and-systemd)


## Pre-requisites

You could use baremetal servers for this demo but you can run it too with just a couple of VMs running on your laptop.

You need an active Red Hat Enterprise Linux subscription.


## Demo preparation

BEFORE delivering the demo, you have to complete these preparation steps.

### Preparing the Image Builder

You need a subscribed [Red Hat Enterprise Linux 9](https://access.redhat.com/downloads/content/479/ver=/rhel---9/9.1/x86_64/product-software) system (minimal install is enough) with at least 2 vCPUs, 4 GB memory and 50 GB disk.

If you don't want to use `root`, be sure that the user has [passwordless sudo access](https://developers.redhat.com/blog/2018/08/15/how-to-enable-sudo-on-rhel).


### Preparing your laptop

Your will need to:

* Install Ansible
```
dnf install -y ansible
```

* Download the `infra.osbuild` Ansible collection
```
ansible-galaxy collection install -f git+https://github.com/redhat-cop/infra.osbuild
```

* Modify the Ansible `inventory` file with your values

* Copy your public SSH key into the Image Builder system, so you can open passwordless SSH sessions with the user that you configured in your Ansible inventory.
```
ssh-copy-id <user>@<image builder IP>
```

* If you are using your laptop as hypervisor, be sure that you have at least 2 vCPU, 1.5GB memory and 20 GB disk free to create the Edge device VM (in addition the Image Builder VM that you should have already up and running).


### Preparing the APPs

In this demo we will be using a couple of simple APPs but you can use your own applications (adapting them to your own use case).

You will need to have access to your own Container Image Repository since during the demo we will need to change published container image tags. In my example I use [Quay.io](https://quay.io). 

Once you have access to your Container Image Registry, create a couple of public namespaces/repositories, in my example I used `2048` and `simple-http`.

Then:

1. Update the `vars/main.yml` file with your Container Image Registry

2. Log in to your Registry (`podman login -u <registry_user> <registry>`) 

3. Run the playbook that will use `skopeo` to copy the images from quay.io/luisarizmendi to your own Registry:

```
ansible-playbook -vvi inventory playbooks/00-preparation-apps.yml
```

Check that you have images in your Registry and that the `prod` image tags are pointing the APP `v1`.

**_NOTE:_** In case that you want to make any changes to the provided APP examples, you can [build your own images using the provided Containerfiles](APPs/README.md).


### Preparing the OSTree images

Run the following Ansible Playbook:

```
ansible-playbook -vvi inventory playbooks/00-preparation-ostree.yml
```

It will:
* Install Image Builder
* Create the OSTree Image v1 and publish it using an HTTP server
* Create the OSTree Image v2
* Create the OSTree Image v3
* Create a RHEL custom ISO that will be used to deploy the RHEL OSTree edge system pointing to the OSTree repo published in the Image Builder (v1)

Once the Ansible Playbook is finished, you will see the URL where the *custom* ISO is published in the last Ansible `debug` message. Download it to the system where you will create the Edge device VM.


## Demo steps

This is the summarized list of the steps to demonstrate the RHEL OSTree and Podman auto-update capabilities (below you will find the detailed description):

0. Step 0 - Review the use cases and the environment
    1. Describe the use case: hands-off deployment + self-healing upgrades in the OS and APPs
    2. Log into the Image Builder and show the images
    3. Show the published OSTree repo and ISO in the HTTP server
1. Step 1 - OS lifecycle: Deploy the edge device using the ISO
    1. Boot the Edge Device from the ISO and watch auto-deployment
    2. Explain how the automation is performed (Kickstart in this case)
    3. SSH to the Edge Device using the admin user
    4. Test the application on `http://<edge_device_IP>:8081`







### Step 0 - Review the use cases and the environment

---
**Summary**

Give an overview of the overall demo steps and explain the setup.

---

We are a company that has a Central Data Center and multiple Edge locations where there are no technical specialized people and we want to cover the following use cases:

1. Deploy a new Edge Device with a simple application
2. Update our Edge Device by adding additional packages (ie. `zsh`)
3. Update the application

In order to demonstrate the "auto-healing" capabilities, we will be introducing an error in both steps 2 and 3, so we can see how the system auto-recovers from that issue, assuring the Edge Device keeps working as expected, then we will solve the issue and perform the update successfully.

The environment is composed of two systems, one is the "Image Builder", which is an already deployed RHEL 9, and an "Edge Device", that will be installed/deployed during the first step.

The Image Builder already has three OSTree images created. The first one is the one that we will use during the first deployment. The second one adds the `zsh` package but removes (by mistake) the `git` package which is needed by the system (let's imagine that one of the system services needs to clone or fetch new files using GIT). The Third image includes the `zsh` package but also keeps the `git` package. 

Follow these steps to review the Image Builder concepts:

1. Log into the Image Builder Cockpit (`https://<image_builder_IP>:9090`) using `root`
2. Go to Image Builder, open the "demo_upgrade" blueprint and explain the Blueprint concept
3. Show the three different images already created, explain the differences between them (installed packages)

As explained, there are three different images already created (to save time during the demo), but just the first one is being "published". The generated OSTree repo is shared using an HTTP service running on the Image Builder (in the future, Ansible Automation Hub will be the preferred way to host the generated OSTree repos). You can check the OSTree repository contents in `http://<image_builder_IP>/demo_upgrade/repo/`

The Image builder also created an installation ISO used to deploy the Edge Device that can be downloaded from `http://<image_builder_IP>/demo_upgrade/images/`. This ISO is already pre-downloaded ready to be used.


### Step 1 - OS lifecycle: Deploy the edge device using the ISO

---
**Summary**

Show how easy is to deploy the Edge Device with a fully automated (hands-off) installation and customization process for both the Operating System and the application.

---

In order to deploy the Edge Device, follow these steps:

1. Create a VM that will be the Edge Device (if you are not using a baremetal machine) with at least 1 vCPU, 1.5GB memory, 20GB disk and one NIC in a network from where it has access to the Image Builder.

2. Use the ISO downloaded from the Image Builder to install the system. Just be sure that the system is starting from the ISO, everything is automatic.

3. Wait until the system prompt.

Meanwhile the system is installing, you can comment that:

* Instead using the ISO directly system by system, you could also host the ISO in an HTTP server centrally and boot systems from network by using UEFI HTTP boot, so the person at the edge location will only need to boot the system (if HTTP Boot has been enable in the device).
* The ISO is a regular RHEL 9 boot ISO with just a change, we introduced in the Kernel Args that makes the system download a kickstart from the Image Builder and execute it (you can review the Kickstar in http://<image_builder_IP>/demo_upgrade/kickstart.ks). This kickstart could be also be injected directly into the ISO instead of downloading it from the Image Builder every time that we deploy a new system.
* We are using a kickstart to automate the OSTree image deployment (the OSTree repo is downloaded from the Image Builder in this case, but it could be also injected in the ISO) along with the different customizations. This is a simple way to customize the deployment but it could introduce risks if we need to include "secrets" such as passwords or certificates in the configuration. In order to perform a secure device deployment you could use FIDO Device Onboarding (FDO). This is not part of this demo but you can learn more about it by running this [FDO workshop](https://luisarizmendi.github.io/tutorial-secure-onboarding).
* All the deployed applications are root-less in order to have an improved security in our system.

Once the deployment finished you can get the system IP and:

**_NOTE:_** Depending on your Internet connection, downloading the images could take some time.

* Test the application at `http://<edge_device_IP>:8081`
* Connect to the system by SSH using the user configured in the Blueprint (`admin`). You shouldn't need password if you used the same laptop from where you ran the demo preparation since the SSH public key was injected into the OSTree image, otherwise you can use the password configured in the Blueprint (`R3dh4t1!`).
* Review the configured systemd service with the root-less contanerized application (`systemctl --user status container-app1.service`) and show the systemd unit file that runs the container (`cat /var/home/admin/.config/systemd/user/container-app1.service`).

### Step 2 - OS lifecycle: Upgrade to OSTree image v2 (with error)
---
**Summary**

Demonstrate the upgrade self-healing feature that automatically rollbacks to the previous known state in case that the upgrade breaks something in either the system or the running applications.

---

Explain that by default, the OSTree Automatic Update Policy is set to `none` which disables automatic updates, but you can change it to `check` option which automatically downloads upgrade metadata to display available updates or `stage` (experimental) option, which downloads and unpacks the update which will be finalized on a reboot.

You can open the configuration file to show that the default is configured:

```
cat /etc/rpm-ostreed.conf


# Entries in this file show the compile time defaults.
# You can change settings by editing this file.
# For option meanings, see rpm-ostreed.conf(5).

[Daemon]
AutomaticUpdatePolicy=none
#IdleExitTimeout=60
```

You can also check the running and the current available image versions:


```
rpm-ostree status


State: idle
Deployments:
● edge:rhel/9/x86_64/edge
                  Version: 0.0.1 (2023-02-09T09:01:58Z)
```

Also check that, at this moment, there are no available upgrades:


```
rpm-ostree upgrade --check


1 metadata, 0 content objects fetched; 196 B transferred in 0 seconds; 0 bytes content written
Note: --check and --preview may be unreliable.  See https://github.com/coreos/rpm-ostree/issues/1579
No updates available.

```


Now it's time to "publish" the new image that was created in advance (to save time) in the Image Builder. Run this Ansible Playbook to do it:

```
ansible-playbook -vvi inventory playbooks/01-publish-image-v2.yml 
```

Once the playbook finishes the new Image is ready and you can check that the Edge Device has a new available image upgrade: 


```
rpm-ostree upgrade --check


2 metadata, 0 content objects fetched; 15 KiB transferred in 0 seconds; 0 bytes content written
Note: --check and --preview may be unreliable.  See https://github.com/coreos/rpm-ostree/issues/1579
AvailableUpdate:
        Version: 0.0.2 (2023-02-09T09:09:19Z)
         Commit: 052229013afc1cb18789991a7d9bcab29272e06eefc6aa0442c352e85c9ad0cf
           Diff: 55 removed, 1 added
```

You can see how the difference between the running image and the new one is that 55 packages were removed and one additional package added. I you want more information about these changes you can check the "preview":


```
rpm-ostree upgrade --preview



1 metadata, 0 content objects fetched; 196 B transferred in 0 seconds; 0 bytes content written
Note: --check and --preview may be unreliable.  See https://github.com/coreos/rpm-ostree/issues/1579
AvailableUpdate:
        Version: 0.0.2 (2023-02-09T09:09:19Z)
         Commit: 052229013afc1cb18789991a7d9bcab29272e06eefc6aa0442c352e85c9ad0cf
        Removed: emacs-filesystem-1:27.2-6.el9.noarch
                 git-2.31.1-3.el9_1.x86_64
                 git-core-2.31.1-3.el9_1.x86_64
                 git-core-doc-2.31.1-3.el9_1.noarch
                 groff-base-1.22.4-10.el9.x86_64
                 ncurses-6.2-8.20210508.el9.x86_64
                 perl-Carp-1.50-460.el9.noarch
                 perl-Class-Struct-0.66-479.el9.noarch
                 perl-DynaLoader-1.47-479.el9.x86_64
                 perl-Encode-4:3.08-462.el9.x86_64
                 perl-Errno-1.30-479.el9.x86_64
                 perl-Error-1:0.17029-7.el9.noarch
                 perl-Exporter-5.74-461.el9.noarch
                 perl-Fcntl-1.13-479.el9.x86_64
                 perl-File-Basename-2.85-479.el9.noarch
                 perl-File-Find-1.37-479.el9.noarch
                 perl-File-Path-2.18-4.el9.noarch
                 perl-File-Temp-1:0.231.100-4.el9.noarch
                 perl-File-stat-1.09-479.el9.noarch
                 perl-Getopt-Long-1:2.52-4.el9.noarch
                 perl-Getopt-Std-1.12-479.el9.noarch
                 perl-Git-2.31.1-3.el9_1.noarch
                 perl-HTTP-Tiny-0.076-460.el9.noarch
                 perl-IO-1.43-479.el9.x86_64
                 perl-IPC-Open3-1.21-479.el9.noarch
                 perl-MIME-Base64-3.16-4.el9.x86_64
                 perl-POSIX-1.94-479.el9.x86_64
                 perl-PathTools-3.78-461.el9.x86_64
                 perl-Pod-Escapes-1:1.07-460.el9.noarch
                 perl-Pod-Perldoc-3.28.01-461.el9.noarch
                 perl-Pod-Simple-1:3.42-4.el9.noarch
                 perl-Pod-Usage-4:2.01-4.el9.noarch
                 perl-Scalar-List-Utils-4:1.56-461.el9.x86_64
                 perl-SelectSaver-1.02-479.el9.noarch
                 perl-Socket-4:2.031-4.el9.x86_64
                 perl-Storable-1:3.21-460.el9.x86_64
                 perl-Symbol-1.08-479.el9.noarch
                 perl-Term-ANSIColor-5.01-461.el9.noarch
                 perl-Term-Cap-1.17-460.el9.noarch
                 perl-TermReadKey-2.38-11.el9.x86_64
                 perl-Text-ParseWords-3.30-460.el9.noarch
                 perl-Text-Tabs+Wrap-2013.0523-460.el9.noarch
                 perl-Time-Local-2:1.300-7.el9.noarch
                 perl-constant-1.33-461.el9.noarch
                 perl-if-0.60.800-479.el9.noarch
                 perl-interpreter-4:5.32.1-479.el9.x86_64
                 perl-lib-0.65-479.el9.x86_64
                 perl-libs-4:5.32.1-479.el9.x86_64
                 perl-mro-1.23-479.el9.x86_64
                 perl-overload-1.31-479.el9.noarch
                 perl-overloading-0.02-479.el9.noarch
                 perl-parent-1:0.238-460.el9.noarch
                 perl-podlators-1:4.14-460.el9.noarch
                 perl-subs-1.03-479.el9.noarch
                 perl-vars-1.05-479.el9.noarch
          Added: zsh-5.8-9.el9.x86_64
```

So `zsh` will be added and `git` (and its dependancies) will be removed if we upgrade the image.


In our use case, we said that we have to imagine that the services running on this Edge Device rely on GIT to fetch files from different repositories, so if we remove GIT from our system, the services won't work as expected. 

We wouldn't like to be checking manually every single image change, so OSTree provices an useful too that you can use to check your system or apps right after the upgrade: Greenboot.

With Greenboot you can write your own check scripts that can, for example, make requests to the running applications, check connectivity to external resources such as databases, or asure that certain tools are available in the system.

You can write check that will show a warning message after the upgrade in case of a failure (the ones located in `/etc/greenboot/check/wanted.d`), but you can also write scripts that, if failed, automatically rollback the upgrade (`/etc/greenboot/check/required.d`). In our case we created a super-simple script that just check that GIT binary is available:

```
cat /etc/greenboot/check/required.d/01_check_git.sh 


#!/bin/bash
git --help
```

This script will fail if we upgrade to the image shown above.... so let's upgrade the system see what happens. 

Let's start by downloading the new image and configuring it to be used in the next reboot:


```
sudo rpm-ostree upgrade 


⠒ Scanning metadata: 1782... 
Scanning metadata: 1782... done
Staging deployment... done
Removed:
  emacs-filesystem-1:27.2-6.el9.noarch
  git-2.31.1-3.el9_1.x86_64
  git-core-2.31.1-3.el9_1.x86_64
  git-core-doc-2.31.1-3.el9_1.noarch
  groff-base-1.22.4-10.el9.x86_64
  ncurses-6.2-8.20210508.el9.x86_64
  perl-Carp-1.50-460.el9.noarch
  perl-Class-Struct-0.66-479.el9.noarch
  perl-DynaLoader-1.47-479.el9.x86_64
  perl-Encode-4:3.08-462.el9.x86_64
  perl-Errno-1.30-479.el9.x86_64
  perl-Error-1:0.17029-7.el9.noarch
  perl-Exporter-5.74-461.el9.noarch
  perl-Fcntl-1.13-479.el9.x86_64
  perl-File-Basename-2.85-479.el9.noarch
  perl-File-Find-1.37-479.el9.noarch
  perl-File-Path-2.18-4.el9.noarch
  perl-File-Temp-1:0.231.100-4.el9.noarch
  perl-File-stat-1.09-479.el9.noarch
  perl-Getopt-Long-1:2.52-4.el9.noarch
  perl-Getopt-Std-1.12-479.el9.noarch
  perl-Git-2.31.1-3.el9_1.noarch
  perl-HTTP-Tiny-0.076-460.el9.noarch
  perl-IO-1.43-479.el9.x86_64
  perl-IPC-Open3-1.21-479.el9.noarch
  perl-MIME-Base64-3.16-4.el9.x86_64
  perl-POSIX-1.94-479.el9.x86_64
  perl-PathTools-3.78-461.el9.x86_64
  perl-Pod-Escapes-1:1.07-460.el9.noarch
  perl-Pod-Perldoc-3.28.01-461.el9.noarch
  perl-Pod-Simple-1:3.42-4.el9.noarch
  perl-Pod-Usage-4:2.01-4.el9.noarch
  perl-Scalar-List-Utils-4:1.56-461.el9.x86_64
  perl-SelectSaver-1.02-479.el9.noarch
  perl-Socket-4:2.031-4.el9.x86_64
  perl-Storable-1:3.21-460.el9.x86_64
  perl-Symbol-1.08-479.el9.noarch
  perl-Term-ANSIColor-5.01-461.el9.noarch
  perl-Term-Cap-1.17-460.el9.noarch
  perl-TermReadKey-2.38-11.el9.x86_64
  perl-Text-ParseWords-3.30-460.el9.noarch
  perl-Text-Tabs+Wrap-2013.0523-460.el9.noarch
  perl-Time-Local-2:1.300-7.el9.noarch
  perl-constant-1.33-461.el9.noarch
  perl-if-0.60.800-479.el9.noarch
  perl-interpreter-4:5.32.1-479.el9.x86_64
  perl-lib-0.65-479.el9.x86_64
  perl-libs-4:5.32.1-479.el9.x86_64
  perl-mro-1.23-479.el9.x86_64
  perl-overload-1.31-479.el9.noarch
  perl-overloading-0.02-479.el9.noarch
  perl-parent-1:0.238-460.el9.noarch
  perl-podlators-1:4.14-460.el9.noarch
  perl-subs-1.03-479.el9.noarch
  perl-vars-1.05-479.el9.noarch
Added:
  zsh-5.8-9.el9.x86_64
Run "systemctl reboot" to start a reboot
```

You can check that in the next reboot, the new image will be used bu running again `rpm-ostree status`. Take a look that the current running version has a dot (`●`) and that the version that is placed in the first place (the one that will be selected by default in the next boot) is the new image:

```
rpm-ostree status


State: idle
Deployments:
  edge:rhel/9/x86_64/edge
                  Version: 0.0.2 (2023-02-09T09:09:19Z)
                     Diff: 55 removed, 1 added

● edge:rhel/9/x86_64/edge
                  Version: 0.0.1 (2023-02-09T09:01:58Z)
```


It's time to reboot, but before running the following command, be sure that you are showing the Edge Device console to being able so see what happens during the reboot process:

```
systemctl reboot
```

While rebooting you can explain that the system will try to boot three times, the first two starting from `ostree:0` (shown in the Grub menu) and the last one will turn back to `ostree:1` which is the second entry that we show in `rpm-ostree status`, so the previous image.

After the third reboot, you will get the command prompt. Try to SSH again to the Edge Device, you will see a message showing that there was a problem with the upgrade:

```
ssh admin@<edge_device_IP>


Boot Status is GREEN - Health Check SUCCESS
FALLBACK BOOT DETECTED! Default rpm-ostree deployment has been rolled back.
Last login: Thu Feb  9 09:46:53 2023 from 192.168.122.1
```

If you check the available images you will see how the "running" image and the "next default image on reboot" are the same, the first image where we have GIT installed.


```
rpm-ostree status


State: idle
Deployments:
● edge:rhel/9/x86_64/edge
                  Version: 0.0.1 (2023-02-09T09:01:58Z)

  edge:rhel/9/x86_64/edge
                  Version: 0.0.2 (2023-02-09T09:09:19Z)
```


### Step 3 - OS lifecycle: Upgrade to OSTree image v3 (OK)
---
**Summary**

Show a sucessful Edge Device upgrade.

---

You need to publish a new image version (v39) that remove `zsh` but keep `git` installed:

```
ansible-playbook -vvi inventory playbooks/01-publish-image-v3.yml 
```

After publishing it, you can check that you have a new upgrade available in the system:



```
rpm-ostree upgrade --check


note: automatic updates (stage) are enabled
2 metadata, 0 content objects fetched; 17 KiB transferred in 0 seconds; 0 bytes content written
Note: --check and --preview may be unreliable.  See https://github.com/coreos/rpm-ostree/issues/1579
AvailableUpdate:
        Version: 0.0.3 (2023-02-09T09:17:09Z)
         Commit: 007328e8dee132c4c16c68ff2874085f2415fcbff5b997b798980c8f4dc5b743
           Diff: 1 added

```


The only difference between the running image and the new image is that `zsh` has been added:

```
rpm-ostree upgrade --preview


note: automatic updates (stage) are enabled
1 metadata, 0 content objects fetched; 196 B transferred in 0 seconds; 0 bytes content written
Note: --check and --preview may be unreliable.  See https://github.com/coreos/rpm-ostree/issues/1579
AvailableUpdate:
        Version: 0.0.3 (2023-02-09T09:17:09Z)
         Commit: 007328e8dee132c4c16c68ff2874085f2415fcbff5b997b798980c8f4dc5b743
          Added: zsh-5.8-9.el9.x86_64
```

Download the image and reboot (with `-r`)

```
sudo rpm-ostree upgrade -r


24 metadata, 3 content objects fetched; 11494 KiB transferred in 0 seconds; 40.1 MB content written
Staging deployment... done
Added:
  zsh-5.8-9.el9.x86_64
```

After the reboot SSH again into the Edge Device:

```
ssh admin@<edge_device_IP>


Boot Status is GREEN - Health Check SUCCESS
Last login: Thu Feb  9 09:54:43 2023 from 192.168.122.1
```

And then check that you are running the most recent image version:


```
[admin@localhost ~]$ rpm-ostree status
State: idle
AutomaticUpdates: stage; rpm-ostreed-automatic.timer: inactive
Deployments:
● edge:rhel/9/x86_64/edge
                  Version: 0.0.3 (2023-02-09T09:17:09Z)

  edge:rhel/9/x86_64/edge
                  Version: 0.0.1 (2023-02-09T09:01:58Z)
```



### Step 4 - APP lifecycle: Upgrade to  APP v2 (with error)
---
**Summary**

.

---

### Step 5 - APP lifecycle: Upgrade to  APP v3 (OK)
---
**Summary**

.

---


### BONUS
---
**Summary**

Demonstrate that people don't need complex systems to have advanced features such as Serverless services, you can implement them in Edge devices with low hardware footprint by using RHEL and Podman, consuming even less resources in your system since the applications won't be running unless they are used.

---

Before using the service is important to explain that the serverless services are not running if they are not being used, so by default the container image won't be pull until the first request to the system... which will imply a delay because the service won't be ready until the image is downloaded. In order to remove that wait during the first request, an auto-pull image service has been created in the system, so the image is ready even before the first request.

You can double-check that the fresh system already have locally the application container image:

1. Find the edge device IP address and ssh to it (using the `admin` user if you used the blueprint example). 

2. Check the `pre-pull-container-image` systemd unit status with `systemctl --user status pre-pull-container-image.service` and show the systemd unit file with `cat /var/home/admin/.config/systemd/user/pre-pull-container-image.service`. Then if the script is finished the container image is ready with `podman image list` (remember that you will have two images, the one used during the previous steps of the demo, and the serverless application, which in my example is `simple-http`).

```
[admin@localhost ~]$ podman image list
REPOSITORY                         TAG         IMAGE ID      CREATED       SIZE
quay.io/luisarizmendi/simple-http  prod        7af8b56b6d83  24 hours ago  296 MB
quay.io/luisarizmendi/2048         prod        21bbdd4e9419  25 hours ago  444 MB
```

3. Now let's prepare for the service request, run a continuous command that check which containers are running on the system with `watch podman ps` and check that you only have one single container running, the one with the service used in the lifecycle demo, but you don't have the one with the Serverless service (`simple-http` in the example). Remember to *let visible the output of the `watch` command* during the next step, so you can notice when the container starts running).

```
CONTAINER ID  IMAGE                            COMMAND     CREATED        STATUS            PORTS                           NAMES
3dc739ae55d8  quay.io/luisarizmendi/2048:prod              5 minutes ago  Up 5 minutes ago  192.168.122.101:8081->8081/tcp  app1
```

4. Access the service published on port 8080 on the edge device (`http://<edge-device-ip>:8080`). The service will return a Text message. At this point you will see in the console running the `watch` command how a new container started as soon as the request was made (Serverless).

5. If you don't request the service again and you wait 10 second, you will be able to see in the console running the `watch` command  how the Serverless service scales down to zero replicas (no container with the service is running) again, saving resources until the system get a new request to the service.

If you want to test the scale-down , just stop the requests to the service and wait 10 seconds, the container should start the shutdown (stop time will depend on the service).

You can also test the Podman image auto-update feature with this service but bear in mind that Podman auto-update works if the container is running, so if your Serverless service scaled-down to zero the new version won't be pulled until the container is started again.











