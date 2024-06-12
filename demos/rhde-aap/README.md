# RHDE management with AAP Demo

## Background 

In this technical demo, we showcase the power of Ansible Automation Platform and Event-Driven Automation in orchestrating and managing the Red Hat Device Edge ecosystem (RHEL and Microshift). Embracing the GitOps methodology, our demonstration highlights how organizations can efficiently manage both the platform and applications by treating infrastructure as code and leveraging version-controlled repositories. 

GitOps principles enable a seamless and auditable approach to infrastructure and application management, offering numerous benefits. By centralizing configuration in Git repositories, organizations gain versioning, change tracking, and collaboration advantages. The demo illustrates how Ansible, a powerful automation tool, combined with GitOps practices, ensures consistency, traceability, and repeatability in the deployment and configuration of Red Hat Device Edge components.


## Table of Contents


- [Red Hat Device Edge GitOps demo](#red-hat-device-edge-gitops-demo)
  - [Table of Contents](#table-of-contents)
  - [Demo duration](#demo-duration)
  - [Lab Architecture](#lab-architecture)
  - [Recommended Hardware](#recommended-hardware)
  - [Required connectivity](#required-connectivity)
  - [Pre-recorded video](#pre-recorded-video)
- [Lab deployment and demo steps](#lab-deployment-and-demo-steps)
  - [Preparation - Deployment and Pre-Flight Checks](#preparation---deployment-and-pre-flight-checks)
  - [Summary and demo step guide](#summary-and-demo-step-guide)
  - [Introduction](#introduction)
  - [Section 1 - Creating RHEL Images the GitOps way](#section-1---creating-rhel-images-the-gitops-way)
  - [Section 2 - Automated device onboarding](#section-2---automated-device-onboarding)
  - [Section 3 - Consistent edge device configuration at scale](#section-3---consistent-edge-device-configuration-at-scale)
  - [Section 4 - Edge computing APPs lifecycle management](#section-4---edge-computing-apps-lifecycle-management)
  - [Section 5 - Bulletproof system upgrades](#section-5---bulletproof-system-upgrades)
  - [Section 6 - Secure Onboarding with FDO](#section-6---secure-onboarding-with-fdo)
  - [Closing](#closing)


## Demo duration

The demo takes at least 120 minutes with no breaks. If you have time, a break after each main section is recommended. 



## Lab Architecture

This is the architecture deployed thanks to the [Ansible Collection](https://galaxy.ansible.com/ui/repo/published/luisarizmendi/rh_edge_mgmt/)

![demo-arch](docs/images/demo-arch.png)

The VPN connection is optional, it's pre-configured and will be setup if you deploy your edge device with the `libreswan` package installed.

  >**Note**
  >
  > In order to connect a machine in the local network to the remote node using the already pre-configured VPN, you will need to use a local subnet contained in `192.168.0.0/16` or `172.16.0.0/12`. It is *very important* that if you are deploying the edge management server locally and you are using a network in that range, that you do DON'T deploy the edge server with the VPN active (that means including the `libreswan` package in the image definition) because there will be routing issues in that case.

## Recommended Hardware

  >**Note**
  >
  > This Lab has been prepared and tested with x86 machines only.

If you plan to use VMs you just need enough free resources in your laptop/server (more or less >6vCPUs, >14GB RAM, >150GB disk) for a couple of VMs:

* Edge Management node: I've been able to deploy everything on a x86 VM with 4 vCores and 10GB of memory. Storage will depend on the number of RHDE images that you generate.

* Edge Device: This will depend on what you install on top, but for the base deployment you can use 2 vCores (x86), 3GB of memory and 50GB disk.


If you use physical hardware you probably will need:
+ Two (mini) x86 servers, one of them with (4vCPUs, 16GB RAM, 50GB+ disk and two network interfaces)
+ One 2GB USB key
+ USB Keyboard (I use one of [this USB RFID mini keyboards](https://www.amazon.es/dp/B07RQBRRR7?psc=1&ref=ppx_yo2ov_dt_b_product_details), but be sure that it does not use just Bluetooth)
+ Video Cable (and HDMI - DisplayPort adapter if needed) and external Monitor to show boot console. If you don't want to use an external screen you can also use a [Video Capture card like this one](https://www.amazon.es/dp/B0CLNHT29F?ref=ppx_yo2ov_dt_b_product_details&th=1) that I use that can show the physical device video output as a video input (camera) in your laptop.
+ Access Point or Router if you don't have a cabled connection to Internet
+ Network Switch if you Access Point / Router does not have at least 2 free interfaces
+ At least 3 RJ45 cables
+ Depending on your laptop you will need aditional adapters (ie. to provide RJ45 interface). Also in certain venues where use HDMI over RJ45 sometimes you could find that your Linux machine does not mirror the screen correctly when using direct HDMI cable, but it works if you connect it to an HDMI port in a USB C adapter, so I finally got [this adapter that has both RJ45 and HDMI output](https://www.amazon.es/dp/B0CBVDRPZD?ref=ppx_yo2ov_dt_b_product_details&th=1).
 
  >**Note**
  >
  > You can also mix VMs and physical servers if you don't have enough Hardware.




## Required connectivity
Internet Connection with access to Red Hat sites, GitHub and Quay.io.

The lab architecture has been designed so you can deploy it where you don't have access to the network to re-configure NAT entries, that means that potentially you could install the edge manager server in, let's say AWS, and the edge device in your local environment/venue network without having to re-configure the router. This is done (for demo pruposes, do not use at production please) using a VPN tunnel between the local and the remote server, so be sure that outgoing IPSec connections are allowed in the Venue firewall if using this setup.

  >**Note**
  >
  > REMEMBER: In order to connect a machine in the local network to the remote node using the already pre-configured VPN, you will need to use a local subnet contained in `192.168.0.0/16` or `172.16.0.0/12`. It is *very important* that if you are deploying the edge management server locally and you are using a network in that range, that you do DON'T deploy the edge server with the VPN active (that means including the `libreswan` package in the image definition) because there will be routing issues in that case.

## Pre-recorded video


You can [take a look at this video](https://www.youtube.com/watch?v=0lUhneAHwEE&list=PL8w3r6_M2eTrZtAcvB2-RjBey1SZ7PFu-) where you can see all the demo steps (you will also find these videos in each demo step section).


You can also watch this [other video](https://youtu.be/XCtfy7AqLLY) where you will find a **similar** flow of the demo but that is explained step by step.


# Red Hat Device Edge GitOps Lab deployment and demo steps


## Preparation - Deployment and Pre-Flight Checks

You can find the steps to deploy the lab here:

* [Lab deployment](docs/lab-deployment.md)


## Summary and demo step guide

The following concepts will be reviewed in this demo:

* Create and publish an OSTree repository using a GitOps approach

* Edge Device installation ISO generation:
  * Injecting kickstart in a base ISO (standard RHEL ISO)
  * Using Image Builder to create a Simplified installer

* Device Onboarding customization using the following different methods:
  * Kickstart
  * Custom RPMs
  * AAP post-automation
  * Ignition files
  * FDO process

* Application deployment using:
  * Podman
    * Using shell scripting
    * Using Quadlet descriptors (GitOps)
  * Microshift
    * Using Manifest (GitOps)
    * Using Help
  * Custom RPM

* Edge Device Self-Healing
  * Auto rollbacks in Operating System Upgrades
  * Edge Device configuration enforcing (GitOps)
  * Podman auto-update rollback

* Extras:
  * Serverless rootless container applications with just Podman



This is the summarized list of the steps (below you will find the detailed description in each section):


* [Summary and demo step guide](docs/s0-summary.md)



## Introduction
In various scenarios, there's a need to deploy applications close to where data is generated due to factors such as limited connectivity, bandwidth, or latency, and sometimes to avoid the high costs of sending data to the cloud or a data center.

In such cases, you encounter unique challenges related to compatibility, security, and especially the scale of the solution. 
Edge computing solutions often involve deploying and managing numerous small devices. It can get even more challenging when you think about deploying devices in remote or costly-to-reach locations, like windmills, offshore oil platforms, or even satellites in space.

To address these challenges you need highly smart automated solutions that will enable you to manage these devices' lifecycle seamlessly, even without direct human intervention, ensuring consistent configuration and behavior across a large scale.

During this demo/workshop will explore how to achieve this consistency using the GitOps approach and how you can simplify lifecycle management in edge locations with the help of features available in OSTree image-based RHEL systems such as Red Hat Device Edge. If you want [to know more about OSTree images you can read this article](https://luisarizmendi.wordpress.com/2022/08/25/a-git-like-linux-operating-system/).

  >**Note**
  >
  > Remember to run the [Pre-flight checks](docs/lab-deployment.md#pre-flight-checks) before running the demo/workshop.


## Section 1 - Creating RHEL Images the GitOps way

In this Section we will cover the following topics:

* Create and publish an OSTree repository using a GitOps approach

* Device Onboarding customization using the following different methods:
  * Kickstart
  * Custom RPMs
  * AAP post-automation

---

First, we want to create a new Red Hat Device Edge (RHDE) image, and we have two options for doing this. The first is through `console.redhat.com`, but we'll choose the other option, the self-provisioned image builder installed on a RHEL machine. 

However, we won't interact with the image builder directly. We will be following the GitOps methodology, which means we have a source of truth, typically a source code control repository like git, where we host the desired configuration for our environment using descriptive configuration files. 

Instead of configuring the image builder directly, we've created a file that describes our desired image, including user settings and software packages, and pushed it to `git`.

To ensure that any changes in this source of truth are applied to our environment, we've configured webhooks. When a change occurs, the Ansible Automation Platform (AAP) automatically enforces the new state by creating a new image using the image builder and publishing it so that end devices can use it.

The demo step descriptions can be found in the following document: 


* [Creating RHEL Images the GitOps way](docs/s1-creating_RHEL_images.md)

After running those steps, we've completed the creation of a new RHDE image using the GitOps approach. 

By following this methodology, we benefit from GitOps features such as increased reliability and stability due to Git's rollback and version tracking capabilities. All of this is possible thanks to the Image builder, which allows us to create images in a descriptive way, and the Ansible Automation Platform, where we can configure Event-Driven Automations, as seen in this Workflow, making it possible to adapt the platform's state to changes in the environment.


## Section 2 - Automated device onboarding

In this Section we will cover the following topics:

* Edge Device installation ISO generation:
  * Injecting kickstart in a base ISO (standard RHEL ISO)

* Device Onboarding customization using the following different methods:
  * Kickstart
  * Custom RPMs
  * AAP post-automation


---


In the first section we created the image and placed it on a web server. Now, we're going to deploy that image on the end device.

In this demo/workshop we will be booting the device directly from the network (the local edge manager server will act as PXE server), eliminating the need for creating a USB with the ISO image, and creating a hands-off installation.

These are the step descriptions for this section:

* [Automated device onboarding](docs/s2-automated-onboarding.md)

The steps above shown a fully automated onboarding experience, and now we have a ready-to-use edge device system included in Ansible Automation Platform for lifecycle management. 

It's important to notice that this means you won't need to send specialized personnel to various locations, saving time and reducing costs in many cases.



## Section 3 - Consistent edge device configuration at scale

In this Section we will cover the following topics:

* Application deployment using:
  * Custom RPM

* Edge Device Self-Healing
  * Edge Device configuration enforcing (GitOps)


---


Managing device configurations at scale is not easy. There is always a risk of config drifts between systems or config version mismatch. We need to enforce a consistency in our platform, otherwise we could head into situations where the behaviour of our solution is not the expected.

By using GitOps, where we have a single source of truth for all our configurations, we can rest assure that a config drift won't happen in our environment, even in the case that someone manually misconfigure something on the end devices, let's see how it works.

In the following steps we demonstrate how this can be done with RHDE and AAP:

* [Consistent edge device configuration at scale](docs/s3-consistent_configuration.md)

The steps above shown how powerful is the usage of event driven automation, since we have made a solution that adapts to events such as someone trying to reconfigure my end devices in a non-desireble way. This will not only save time by automating device configuration at scale, but for sure will reduce the risk of issues in your solution due to configuration drifts.


## Section 4 - Edge computing APPs lifecycle management

In this Section we will cover the following topics:

* Application deployment using:
  * Podman
    * Using shell scripting
    * Using Quadlet descriptors (GitOps)
  * Microshift
    * Using Manifest (GitOps)
    * Using Help
  * Custom RPM

* Edge Device Self-Healing
  * Podman auto-update rollback

 * Extras:
   * Serverless rootless container applications with just Podman


---

When we consider the applications used in edge computing scenarios, we find a wide variety of options. However, for such applications, we need the platform to meet at least three key requirements:

* Resource Efficiency: Edge devices often have limited hardware resources, so applications must consume as few resources as possible.
* Automated Lifecycle Management: Applications should be fully automated, including upgrades.
* Self-Healing: Applications should be resilient, and capable of recovering from critical failures.

While similar capabilities might exist in public clouds or data centers, the hardware used in edge computing solutions is different. Due to hardware limitations, deploying a full Kubernetes cluster, which is common in data centers for serverless applications, might not be feasible in these scenarios. Here, we must consider trade-offs between capabilities and hardware resources consumed by the platform. 

Thanks to Red Hat Device Edge we can choose between two different approaches to deploy and manage APPs at the Edge taking those constraints into consideration while deploying our containerized applications

* Use just Podman and Systemd

* Use Microshift (Kubernetes API), an upstream kubernetes project that includes some of the OpenShift APIs designed to be executed in small hardware footprint devices.

This section is divided in two. In the first part, we will manage applications that are deployed with just Podman/Systemd (no Kubernetes at all) and during the second one we will introduce Kubernetes workloads by using `Microshift`.



### APPs with Podman and Systemd

The steps to show the application deployment and lifecycle management using Podman can be found here:

* [Edge computing APPs lifecycle management - APPs with Podman and Systemd](docs/s4-app-lifecycle-podman.md)

We have shown how, thanks to Podman and Systemd, it's possible to include complex deployments, like serverless services with auto-update and self-healing, on small hardware footprint devices without needed additional layers such as the Kubernetes API. 

This means you don't have to sacrifice useful features when using small hardware footprint devices. Podman makes the most out of your hardware.


### APPs with Microshift

Now an idea of how you could manage Microshift using Ansible Collections through the Ansible Automation Platform:

**IMPORTANT**

In this demo/workshop we are bringing some ideas about how to build a gitops-like environment using just Ansible Automation Platform (AAP). This is a great approach when using applications deployed using Podman, but when you introduce a Kubernetes API it's even better to complement the AAP with the use of any of the existing GitOps tools (ie. ArgoCD) or Kubernetes API-focused management products, for example, Red Hat Advance Cluster Management (ACM). In the specific case of Microshift, at this moment (January'24) the management of applications on top of Microshift using ACM is a technical preview feature and in the near future Microshift will be supporting dedicated GitOps tools.

Demo/workshop steps for APP lifecycle ideas with AAP and Microshift:

* [Edge computing APPs lifecycle management - APPs with Microshift](docs/s4-app-lifecycle-microshift.md)

We have seen that in addition to what we can get with Podman, we can also make use of the Kubernetes API in Red Hat Device Edge (This flexibility is even greater if you think that you can also deploy traditional non-containerized applications as part of the Red Hat Device Edge images, although this is not covered in this demo/workshop).

In summary, it's all about deciding where to place your workload and how you want to run it.



## Section 5 - Bulletproof system upgrades

In this Section we will cover the following topics:

* Edge Device Self-Healing
  * Auto rollbacks in Operating System Upgrades


---


Imagine that you have a system running in a windmill in the middle of a mountain. You decide to upgrade you Operating System... and then in the process suddenly.. nothing works, you dont' even have access to the system to try to recover it...You will need to send someone to that remote mountain in an off-road truck who knows how to connect and fix the issue. That means a lot of time and money.

What if you system detects the failure or that something is not working as expected and then, automatically rolls back to the previous version where things were working correctly? that's possible thanks to OSTree images and Greenboot.

The following steps go thought this upgrade experience:

* [Bulletproof system upgrades](docs/s5-system-upgrades.md)

We have seen an automatic OS rollback and, what is more important, we assured that our edge devices will be working as expected after an upgrade that, in other circumstances, would have headed into a system with unexpected failures.

This time we shown just with a simple script that checks OS packages, but you can also write health-checks that monitor the status of your applications right after the upgrade, or the connectivity, or any benchmark that you define.

With Greenboot you can create a trully bulletproof system upgrades, you won't find again problems like the ones described before that imply high costs and delays in case of edge computing use cases.




## Section 6 - Secure Onboarding with FDO

In this Section we will cover the following topics:

* Create and publish an OSTree repository using a GitOps approach

* Edge Device installation ISO generation:
  * Using Image Builder to create a Simplified installer

* Device Onboarding customization using the following different methods:
  * Ignition files
  * FDO process

---

In the previous sections, different ways of performing automatic onboarding (kickstart, custom RPMs, automation from AAP) were demonstrated, but still there is one important point that needs to be reviewed: How to include secrets and sensitive data in your automatic onboarding process.

So far, this demo has shown how the devices are being onboarded in AAP without authentication (check the AAP onboarding script in the kickstart file for example). Now imagine that you want to include a bearer token to include in the webhook, How would you include that secret information? Beyond AAP authentication there could be a lot of different use cases where you need to include passwords, certificates, keys, etc as part of the device onboarding (ie. if you deploy the edge management AAP server outside the edge device location you will need to setup a VPN that actually needs a Pre-shared key in this demo), so this is a critical point part of your onboarding process design.

Think about the three methods to include customizations during the onboarding that we have seen so far:

* Customizations with Kickstart: The secrets are either downloaded from a remote server or injected in the ISO but in both cases they will be in plain text. If you plan to encrypt those you will have the problem that you will also need to include the key as part of the onboarding so it won't be secure in any case.

* Customizations with custom RPM: Same case than kickstart. The secrets must be readable by the automated onboarding script embedd in the RPM

* Customizations from AAP: In this case you could inject the secret as a post-deployment step ("late binding") or split the encrypted secret from the key used to decrypt it, the problem comes when the secret that you would like to inject in the onboarding is the AAP authentication (that you need before launching automations from AAP) or while setting up the VPN to connect to the edge management server, in that case you still need to rely in other methods to include that "first secret" into the edge device.

At the end of the day, you will need a system that brings secret "late binding" to the onboarding process. You could design your own solution that stores and shared the sensitive information in a secure way, but you can also take another alternative, use the [FIDO Device Onboarding specificication](https://fidoalliance.org/device-onboarding-overview/) to build it... or even better, use the already developed FDO servers provided by Red Hat. This is what we are going to see in this section.

If you want [to know more about FDO you can read this article series](https://luisarizmendi.wordpress.com/2022/08/08/edge-computing-device-onboarding-part-i-introducing-the-challenge/).


* [Secure Onboarding with FDO](docs/s6-secure-onboarding-with-fdo.md)

This section reviewed how you can take advantage of the Red Hat implementation of the FDO specification, and how you can use [Ignition](https://coreos.github.io/ignition/) to inject onboarding customizations in the Simplified Installer ISO created by the image builder.

Thanks to FDO, you can get a secure onboarding process, removing the risk of someone stealing your image or device and having access to sensitive data.



## Closing
During the demo/workshot we saw:

* How we created a RHEL image by just defining it in a file descriptor located in a source code repository

* How that image was deployed with a hands-off-installation where there was no human interaction, and how besides the OS installation the complete onboarding process was performed automatically in external tools such as the Ansible Controller.

* Then we show how with just Podman we created a serverless self-healing application with auto-updates enabled, using few system resources, which is a great benefit for edge computing systems

* We configured our systems following the GitOps approach, enforcing the right configurations at scale in all our systems assuring the consistency even in case of a manual override locally

* And finally we show how we prevent an OS system upgrade to break the desired behaviour of our edge computing edge devices, by performing a system rollback automatically when a failure was detected.

The demo of Ansible Automation Platform and Red Hat Device Edge showcased several compelling features and capabilities that promise to bring significant benefits to our edge computing solutions. In particular, the self-healing capabilities and automation at scale offer the following advantages for our use cases in edge computing:

* Simplified Management: The demo illustrated how Ansible Automation Platform can provide a centralized management solution for your distributed edge computing infrastructure. This simplified management is crucial for our organization as it allows us to oversee and control a large number of edge devices and applications from a single point. This streamlined management approach not only reduces operational complexity but also enhances our team's efficiency by providing a unified interface for configuration, monitoring, and troubleshooting.

* Efficient Over-the-Air Updates: One of the key challenges in edge computing is keeping devices up-to-date with the latest software and security patches. The demonstration highlighted how Red Hat Device Edge enables efficient over-the-air updates. This feature is essential for maintaining the health and security of our edge devices without manual intervention. By automating the update process, we can ensure that all edge devices are running the latest software, reducing vulnerabilities and improving overall system reliability.

* Platform Consistency: Ensuring platform consistency across all edge devices is critical for maintaining a robust and predictable edge computing environment. The demo showcased how Ansible Automation Platform can enforce consistent configurations and policies across diverse hardware and software platforms. This standardization minimizes configuration drift and reduces the chances of compatibility issues, ultimately leading to a more stable and reliable edge infrastructure.

* Unattended Resilience: The self-healing capabilities of Ansible Automation Platform and Red Hat Device Edge are particularly valuable for our edge computing use cases. These capabilities allow the system to detect and respond to failures automatically, minimizing downtime and ensuring uninterrupted operation. Whether it's rebooting a malfunctioning device, load balancing traffic, or handling system errors, the ability to achieve unattended resilience is a significant advantage in edge computing, where human intervention may not always be practical.

In addition to these benefits, the demo also emphasized the scalability and adaptability of these solutions. As our edge computing infrastructure continues to grow, the ability to automate tasks and processes at scale becomes increasingly important. Ansible Automation Platform and Red Hat Device Edge can help us meet these demands by efficiently managing and orchestrating our edge devices and applications.

Overall, the combination of Ansible Automation Platform and Red Hat Device Edge, with their self-healing capabilities and automation at scale, promises to simplify management, enable efficient over-the-air updates, ensure platform consistency, and provide unattended resilience for our edge computing solutions. These advantages are essential for our organization's success in the rapidly evolving world of edge computing.





