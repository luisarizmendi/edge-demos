# config_rh_edge_mgmt_node role

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


### Variables

  >**Note**
  >
  > Not all variables will be explained in this README, you can always take a look at the [role default variables](defaults/main.yml).


You can skip a service configuration by configuring any of these variables to false:

```yaml
include_aap: false
include_gitea: false
```

#### Gitea

There are two different types of users. There is one that will become the gitea admin, who can manage users, and the rest will be "regular" users, who will have access to their repos but nothing more.

* Admin

You can setup the default name and password with the following variables (if you don't configure the variables, the defaults will be `gitea`/`R3dh4t1!`, you cannot use the name "admin" since it is reserved)

```yaml
gitea_admin_name: gitea
gitea_admin_password: R3dh4t1!
```

You can add repos under the "admin" user by providing the path to the file templates of these repos (the name of the root directories will be the repo names) using the `gitea_admin_repos_template` variable. For example, if you configure the variable:

```yaml
gitea_admin_repos_template: ../templates/gitea_admin_repos
```

and under that path you have the following:

```
templates/gitea_admin_repos/
└── eda
    └── rulebooks
        └── rulebook.yml
└── myrepo
    └── README.md
```

Two different repos will be configured (`eda` and `myrepo`).


* Regular users

You can configure certain amount of regular users by including the user number using the `gitea_user_count` variable, for example, to configure three users you will setup the variable in this way:

```yaml
gitea_user_count: 3
```

  >**Note**
  >
  > If you configure it to `0`, no additional users will be generated. Default is `3`.


The names of the users will be generated as <base username><number> and the passwords <base password><number>. The default base username is "user" and the default base password is "password", but those can be configured with the following variables if needed:

```yaml
gitea_user_name: user
gitea_user_password: password
```

Following the previous example with three different users, the third user will have a user name of `user3` and the password `password3`

As with the Admin repos, you can add user repos by configuring the variable `gitea_user_repos_template` pointing to the location where the file templates for the repos are located.


#### Ansible Automation Platform

You need to prepare  two variables for the AAP:

* `aap_config_template`: template file with the AAP configuration

* `aap_repo_name`: name of the repository where the AAP playbooks will be hosted in the user's repositories in Gitea.

A possible configuration example for these variables could be:

```yaml
aap_config_template: ../templates/aap_config.j2
aap_repo_name: aap
```

You can customize other aspects of the AAP configuration, for example, you can change the name of users, or the username / password defaults (which are generated in the same way than for the Gitea repository) by including the following variables:

```yaml
aap_user_count: 3
aap_user_name: user
aap_user_password: password
```

Tou can also configure the admin user and password for both the Controller and EDA with the variables (the example is with the default values):

```yaml
controller_username: "admin"
controller_password: "R3dh4t1!"
eda_username: "admin"
eda_password: "R3dh4t1!"
```


### Templates

As mentioned, you will need the file templates that will generate the different repositories for both users and admin. Those files, that are Jinja templates,  can be under subdirectories (the same directory layout will be generated in the repository). 


## Role Usage

### Inventory

Create the inventory file where the AAP and the Gitea are installed. 

```yaml
---
all:
  hosts:
    edge_management:
      ansible_host: 192.168.122.70
      ansible_port: 22
      ansible_user: admin
```

  >**Note**
  >
  > If you have your Gitea in different host or port, you can configure them with the variables `gitea_ip` and `gitea_port`.



### Create a Playbook that uses the role

Create a playbook that will launch the role, for example:

```bash
mkdir playbooks
vi playbooks/main.yml
```


Use a task to call the role, as it appears in the example below, including your variables:


```yaml
- name: Config management node
  ansible.builtin.include_role:
    name: ../../../../common/roles/config_rh_edge-mgmt-node
  vars:
    gitea_admin_repos_template: ../templates/gitea_admin_repos
    gitea_user_repos_template: ../templates/gitea_user_repos
    aap_config_template: ../templates/aap_config.j2
    aap_repo_name: aap
```


### Launch the playbook 

Launch the playbook using following command (if your playbook is in `playbooks/main.yml`):

```bash
ansible-playbook -vvi inventory  playbooks/main.yml
```
