# APPs with Microshift

During the onboarding, Applications are deployed automatically into Microshift in two ways during this demo:
  * Using the manifest located in Gitea (`rhde/prod/rhde_config/microshift/manifest`) 
  * Using the manifest located in `/usr/lib/microshift/manifests/`. Those manifest were created by a custom RPM (`workload-manifests`) installed while preparing the RHDE image.  
  
  
Depending on the network Bandwidth and the system resources, Microshift can take some time to start since it needs to download the container images and run the required PODs (I've seen even 15 minutes delays). While starting you will see PODs such as `ovnkube-master`, `ovnkube-node` and `node-resolver` in `ContainerCreating` and the rest of PODs in `Pending`.

If after some time your PODs are still not running, it could happen that your system does not have a right `pull-secret` configured in `/etc/crio/openshift-pull-secret` (it should have been deployed by AAP during the onboarding from Gitea).

You can show how the APPs are running by following these steps:

1) Connect using SSH to the edge device

2) Review all the deployed Microshift PODs:

```bash
oc --kubeconfig /var/lib/microshift/resources/kubeadmin/kubeconfig get pods --all-namespaces
```

3) You can check the embeded manifest in the RHDE image located in `rhde/prod/rhde_config/microshift/manifest`


4) Check the APP routes

```bash
oc --kubeconfig /var/lib/microshift/resources/kubeadmin/kubeconfig get route --all-namespaces
```

5) Connect to any of the APPs deployed automatically during onboarding

.
  >**Note**
  >
  > Microshift, which is a Kubernetes node, will rely on a wildcard domain name to publish the APPs. Since the edge device IP is not fixed by the playbooks we don't setup any DNS entry on the edge local server. The easiest way to obtain a wildcard for this demo is by using the [nio.ip](http://nio.io) service which resolves to the IP that you use as a prefix on the domain name (so `http://1.1.1.1.nip.io` will resolve to `1.1.1.1`). As you can see there is already a deployed test app that you can check on `http://test.apps.<edge device ip>.nip.io` on the Web Browser with the SOCKS proxy configured..


## Deploy an APP on Microsift with external Helm repo and vars file on Gitea 

Now we are going to deploy a new APP on Microshift. We could just add more Manifest into Gitea and those will be automatically deployed on the RHDE devices (there is a hook configured pointing to the Event Driven Automation endpoint), but this time we are going to do it by using Helm. 

In Gitea you can find under `rhde/prod/rhde_config/microshift/helm` the Helm variables used by an example `wordpress` APP. You can launch the deployment from AAP:

1. Open `rhde/prod/rhde_config/microshift/helm/wordpress/wordpress_vars.yml` where you will find the definition of the variables for a Helm Chart that deploys `Wordpress`.

2. Either change something in that file (ie. the `wordpressBlogName`) or launch manually the AAP Template "Microshift APP Deploy - Helm" to get installed the APP on the edge device

  >**Note**
  >
  > The Helm Chart repo (`https://raw.githubusercontent.com/luisarizmendi/helm-chart-repo/main/packages`) and Chart (the one that deploys `Wordpress`) are defined on the variables associated to the AAP Template. This is just an example for the demo, in production there might be better ways to do it, more if you use many different Helm Charts.

3. Wait until the PODs are running and show the APP on the Web Browser with the SOCKS proxy configured at `http://wordpress-wordpress.apps.<edge device ip>.nip.io`

Now you can show how to modify the APP by just changing the values on the Gitea.

4. Open `rhde/prod/rhde_config/microshift/helm/wordpress/wordpress_vars.yml` and change the `replicaCount` number

5. Wait and see how that number of replicas is deployed on Microshift.

  >**Note**
  >
  > That will be the replicaCount of just the Wordpress frontend, the mysql database will keep one single replica.



