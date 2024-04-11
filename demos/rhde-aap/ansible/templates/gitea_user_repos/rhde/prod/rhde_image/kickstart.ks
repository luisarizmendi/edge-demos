{% if wifi_network is defined and wifi_password is defined %}
%pre
nmcli dev wifi connect "{{ wifi_network }}" password "{{ wifi_password }}"
%end
{% endif %}
{% if wifi_network is not defined  %}
network --bootproto=dhcp --onboot=true
{% endif %}
lang en_US.UTF-8
keyboard us
timezone Etc/UTC
text
zerombr
clearpart --all --initlabel
part /boot/efi --fstype=efi --size=200
part /boot --fstype=xfs --asprimary --size=800
part swap --fstype=swap --recommended
part pv.01 --grow
volgroup rhel pv.01
logvol / --vgname=rhel --fstype=xfs --percent=90 --name=root
reboot
graphical
user --name=ansible --groups=wheel --password='{{  gitea_user_password }}{{ user_number  }}'
rootpw --plaintext --lock '{{  gitea_user_password }}{{ user_number  }}'
services --enabled=ostree-remount
ostreesetup --nogpg --url=http://{{ ansible_host }}/student-repos/student{{ user_number }}/repo --osname=rhel --ref=rhel/9/x86_64/edge

%post --log=/root/kickstart-post.log
set -x

firewall-offline-cmd --zone=trusted --add-source=10.42.0.0/16
firewall-offline-cmd --zone=trusted --add-source=169.254.169.1
firewall-offline-cmd --zone=public --add-port=80/tcp
firewall-offline-cmd --zone=public --add-port=443/tcp
firewall-offline-cmd --zone=public --add-port=6443/tcp


cat > /etc/microshift/config.yaml <<EOF
dns:
  baseDomain: $(hostname -I | awk '{print $1}').nip.io
network:
  clusterNetwork:
    - 10.42.0.0/16
  serviceNetwork:
    - 10.43.0.0/16
  serviceNodePortRange: 30000-32767
node:
  hostnameOverride: "edge-$(ip addr | grep $(nmcli con show | grep -v UUID | head -n 1 | awk '{print $1}') -A 1 | grep link | awk '{print $2}' | sed 's/://g')"
  nodeIP: "$(nmcli conn show $(nmcli con show | grep -v UUID | head -n 1 | awk '{print $1}') | grep ip_address | awk '{print $4}')"
apiServer:
  subjectAltNames:
    - microshift.lablocal
    - microshift.$(hostname -I | awk '{print $1}').nip.io
    - $(hostname -I | awk '{print $1}')
debugging:
  logLevel: "Normal"

EOF


cat > /etc/crio/openshift-pull-secret <<EOF
{{ pull_secret | default('INCLUDE-YOUR-PULL-SECRET') }}
EOF
sudo chown root:root /etc/crio/openshift-pull-secret
sudo chmod 600 /etc/crio/openshift-pull-secret



cat <<EOF > /etc/microshift/manifests/kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
  - testapp.yaml

patches:
  - patch: |-
      - op: replace
        path: "/spec/host"
        value: test.apps.$(hostname -I | awk '{print $1}').nip.io
    target:
      kind: Route
EOF


cat <<EOF > /etc/microshift/manifests/testapp.yaml
apiVersion: v1
kind: Namespace
metadata:
  labels:
    kubernetes.io/metadata.name: test
  name: test
spec: {}
---
apiVersion: apps/v1
kind: Deployment
metadata:
  labels:
    app: hello
  name: test-hello
  namespace: test
spec:
  replicas: 1
  selector:
    matchLabels:
      app: hello
  strategy:
    rollingUpdate:
      maxSurge: 25%
      maxUnavailable: 25%
    type: RollingUpdate
  template:
    metadata:
      creationTimestamp: null
      labels:
        app: hello
    spec:
      containers:
      - image: quay.io/luisarizmendi/hello-js:latest
        imagePullPolicy: Always
        name: hello-js
        resources: {}
        terminationMessagePath: /dev/termination-log
        terminationMessagePolicy: File
        volumeMounts:
        - mountPath: /mnt
          name: my-volume
      volumes:
      - name: my-volume
        persistentVolumeClaim:
          claimName: test-lv-pvc
      dnsPolicy: ClusterFirst
      restartPolicy: Always
      schedulerName: default-scheduler
      securityContext: {}
      terminationGracePeriodSeconds: 30
---
kind: PersistentVolumeClaim
apiVersion: v1
metadata:
  name: test-lv-pvc
  namespace: test
spec:
  accessModes:
  - ReadWriteOnce
  resources:
    requests:
      storage: 1G
---
apiVersion: v1
kind: Service
metadata:
  name: test-nodeport
  namespace: test
spec:
  type: NodePort
  selector:
    app: hello
  ports:
    - name: http
      port: 8080
      targetPort: 8080
      nodePort: 30080
---
apiVersion: v1
kind: Service
metadata:
  name: test-service
  namespace: test
spec:
  selector:
    app: hello
  ports:
  - name: http
    protocol: TCP
    port: 8080
    targetPort: 8080

---
apiVersion: route.openshift.io/v1
kind: Route
metadata:
  name: test-route
  namespace: test
spec:
  host: APP-HOST
  port:
    targetPort: 8080
  to:
    kind: Service
    name: test-service
    weight: 10
EOF


{% if lab_wifi_network.ssid is defined and lab_wifi_network.password is defined %}
cat > /etc/systemd/system/connect-wifi.service <<EOF
[Unit]
Description=Connect to lab WiFi
After=network.target
ConditionPathExists=!/var/tmp/wifi-connected

[Service]
Type=oneshot
ExecStartPre=/usr/bin/nmcli radio wifi on
ExecStartPre=/usr/bin/sleep 5
ExecStartPre=/usr/bin/nmcli dev wifi rescan
ExecStartPre=/usr/bin/sleep 5
ExecStartPre=/usr/bin/nmcli dev wifi list
ExecStart=/usr/bin/nmcli dev wifi connect {{ lab_wifi_network.ssid }} password '{{ lab_wifi_network.password }}'
ExecStopPost=/usr/bin/touch /var/tmp/wifi-connected

[Install]
WantedBy=default.target
EOF
{% endif %}



cat > /var/tmp/aap-auto-registration.sh <<EOF
#!/bin/bash
conn_name=\$(nmcli con show | grep -v UUID | head -n 1 | awk '{print \$1}')
IP_ADDRESS=\$(nmcli conn show \$conn_name | grep ip_address | awk '{print \$4}')

#MAC_ADDRESS=\$(ip addr | grep wlp -A 1 | grep link | awk '{print \$2}' | sed 's/://g')
MAC_ADDRESS=\$(ip addr | grep \$conn_name -A 1 | grep link | awk '{print \$2}' | sed 's/://g')
STUDENT='{{ user_number }}'


if [ -z "\$IP_ADDRESS" ] || [ -z "\$MAC_ADDRESS" ] || [ -z "\$STUDENT" ]; then
    echo "One or more required variables are empty. Script failed."
    exit 1
fi

JSON="{\
\"ip_address\": \"\$IP_ADDRESS\", \
\"student\": \"\$STUDENT\", \
\"mac_address\": \"\$MAC_ADDRESS\" \
}"

/usr/bin/curl -H 'Content-Type: application/json' --data "\$JSON" https://{{ ansible_host }}/endpoint
EOF

chmod +x  /var/tmp/aap-auto-registration.sh


cat > /etc/systemd/system/aap-auto-registration.service <<EOF
[Unit]
Description=Register to Ansible Automation Platform
After=network.target
After=connect-wifi.service
ConditionPathExists=!/var/tmp/aap-registered

[Service]
Type=simple
ExecStart=/bin/bash -c 'while true; do /var/tmp/aap-auto-registration.sh && /usr/bin/touch /var/tmp/aap-registered && break; done'

[Install]
WantedBy=default.target
EOF

systemctl daemon-reload
systemctl enable connect-wifi.service
systemctl enable aap-auto-registration.service




### python3-inotify

## **** REMEMBER TO HAVE PYTHON3-INOTIFY INSTALLED


pip3 install inotify requests

# Create the Python script to watch /etc and send a webhook with JSON data
cat <<EOF > /usr/local/bin/watch_etc.py
#!/usr/bin/env python3

import inotify.adapters
import requests
import os
import subprocess
import time

time.sleep(15)

# Define the directory to monitor
DIRECTORY = '/etc'

# Define your webhook URL
WEBHOOK_URL = "https://{{ ansible_host }}/endpoint"
{% raw %}
# Function to send a webhook with JSON data
def send_webhook(path, filename, event_type, student, inventory):
    json_data = {
        "student": student,
        "inventory": inventory,
        "path": path,
        "file_changed": filename,
        "event_type": event_type
    }

    headers = {'Content-Type': 'application/json'}
    response = requests.post(WEBHOOK_URL, json=json_data, headers=headers)
    if response.status_code == 200:
        print(f'Webhook sent: {filename}')

# Check if the "/root/inotify-wait" file exists
def inotify_wait_exists():
    return os.path.exists('/root/inotify-wait')

try:
    conn_name = subprocess.check_output("nmcli con show | grep -v UUID | head -n 1 | awk '{{print \$1}}'", shell=True)
    conn_name = conn_name.decode("utf-8").strip()
except subprocess.CalledProcessError as e:
    print(f"Error running the first shell command: {e}")
    conn_name = None

# Check if the connection name was retrieved successfully
if conn_name:
    # Run the second shell command to get the MAC address
    try:
        MAC_ADDRESS = subprocess.check_output(f"ip addr | grep {conn_name} -A 1 | grep link | awk '{{print \$2}}' | sed 's/://g'", shell=True)
        MAC_ADDRESS = MAC_ADDRESS.decode("utf-8").strip()
    except subprocess.CalledProcessError as e:
        print(f"Error running the second shell command: {e}")
        MAC_ADDRESS = None

# Check if both variables are available
if conn_name and MAC_ADDRESS:
    inventory = f'edge-{MAC_ADDRESS}'

# Initialize the inotify watcher
i = inotify.adapters.InotifyTree(DIRECTORY)
{% endraw %}
for event in i.event_gen(yield_nones=False):
      (_, type_names, path, filename) = event
      # Check the file extension and skip unwanted extensions
      _, file_extension = os.path.splitext(filename)

      if file_extension not in ('.swp', '.ddf', '.db'):
        #print("variable: {}".format(type_names))
        if any(event_type in ['IN_CREATE', 'IN_MODIFY', 'IN_DELETE', 'IN_MOVE'] for event_type in type_names):
            print("PATH=[{}] FILENAME=[{}] EVENT_TYPES={}".format(path, filename, type_names))
            # Check if the "/root/inotify-wait" file exists
            if not inotify_wait_exists():
                # Send a webhook notification with JSON data
                send_webhook(path, filename, type_names, {{ user_number }}, inventory )
                # Create the "/root/inotify-wait" file
                open('/root/inotify-wait', 'w').close()

i.remove_watch(DIRECTORY)
EOF

# Make the script executable
chmod +x /usr/local/bin/watch_etc.py

semanage fcontext -a -t bin_t '/usr/local/bin/watch_etc.py'
restorecon -v '/usr/local/bin/watch_etc.py'



# Define the webhook URL (replace with your actual URL)
WEBHOOK_URL="https://{{ ansible_host }}/endpoint"

# Create a systemd service unit to run the Python script
cat <<EOF > /etc/systemd/system/watch-etc.service
[Unit]
Description=Watch /etc for file changes and send a webhook

[Service]
ExecStart=/usr/local/bin/watch_etc.py
Restart=always

[Install]
WantedBy=multi-user.target
EOF

# Reload systemd to read the new unit file
systemctl daemon-reload

# Enable and start the service
systemctl enable watch-etc.service
systemctl start watch-etc.service







########## PODMAN autoupdate rootless


# create systemd user directories for rootless services, timers, and sockets
mkdir -p /var/home/ansible/.config/systemd/user/default.target.wants
mkdir -p /var/home/ansible/.config/systemd/user/sockets.target.wants
mkdir -p /var/home/ansible/.config/systemd/user/timers.target.wants
mkdir -p /var/home/ansible/.config/systemd/user/multi-user.target.wants

cat > /var/home/ansible/.config/systemd/user/podman-auto-update.service <<EOF
[Unit]
Description=Podman auto-update service
Documentation=man:podman-auto-update(1)

[Service]
ExecStart=/usr/bin/podman auto-update

[Install]
WantedBy=multi-user.target default.target
EOF



# This timer ensures podman auto-update is run every minute
cat > /var/home/ansible/.config/systemd/user/podman-auto-update.timer <<EOF
[Unit]
Description=Podman auto-update timer

[Timer]
# This example runs the podman auto-update daily within a two-hour
# randomized window to reduce system load
#OnCalendar=daily
#Persistent=true
#RandomizedDelaySec=7200

# activate every minute
OnBootSec=30
OnUnitActiveSec=30

[Install]
WantedBy=timers.target
EOF


# define listener
node_ip=$(ip a show dev $(ip route | grep default | awk '{print $5}') | grep "inet " | awk '{print $2}' | awk -F / '{print $1}')


##
## Create a service to launch the container workload and restart
## it on failure
##
cat > /var/home/ansible/.config/systemd/user/container-app1.service <<EOF
# container-app1.service
# autogenerated by Podman 4.2.0
# Wed Feb  8 10:13:55 UTC 2023

[Unit]
Description=Podman container-app1.service
Documentation=man:podman-generate-systemd(1)
Wants=network-online.target
After=network-online.target
RequiresMountsFor=%t/containers

[Service]
Environment=PODMAN_SYSTEMD_UNIT=%n
Restart=on-failure
TimeoutStopSec=70
ExecStartPre=/bin/rm -f %t/%n.ctr-id
ExecStart=/usr/bin/podman run \
        --cidfile=%t/%n.ctr-id \
        --cgroups=no-conmon \
        --rm \
        --sdnotify=conmon \
        -d \
        --replace \
        --name app1 \
        --label io.containers.autoupdate=registry \
        -p ${node_ip}:8081:8081 {% raw %}{{ apps.app1.registry }}/{{ apps.app1.image }}:{{ apps.app1.prodtag }}{% endraw %}
ExecStop=/usr/bin/podman stop --ignore --cidfile=%t/%n.ctr-id
ExecStopPost=/usr/bin/podman rm -f --ignore --cidfile=%t/%n.ctr-id
Type=notify
NotifyAccess=all
RestartSec=10
StartLimitIntervalSec=120
StartLimitBurst=5

[Install]
WantedBy=default.target
EOF


# enable connection through the firewall
cat << EOF > /etc/systemd/system/expose-container-app1.service
[Unit]
Wants=firewalld.service
After=firewalld.service

[Service]
Type=oneshot
ExecStart=firewall-cmd --permanent --add-port=8081/tcp
ExecStartPost=firewall-cmd --reload

[Install]
WantedBy=multi-user.target default.target
EOF


# enable services
ln -s /var/home/ansible/.config/systemd/user/podman-auto-update.timer /var/home/ansible/.config/systemd/user/timers.target.wants/podman-auto-update.timer

ln -s /var/home/ansible/.config/systemd/user/container-app1.service /var/home/ansible/.config/systemd/user/default.target.wants/container-app1.service
ln -s /var/home/ansible/.config/systemd/user/container-app1.service /var/home/ansible/.config/systemd/user/multi-user.target.wants/container-app1.service

systemctl enable expose-container-app1.service



# fix ownership of user local files and SELinux contexts
chown -R ansible: /var/home/ansible
restorecon -vFr /var/home/ansible


# enable linger so user services run whether user logged in or not
cat << EOF > /etc/systemd/system/enable-linger.service
[Service]
Type=oneshot
ExecStart=loginctl enable-linger ansible

[Install]
WantedBy=multi-user.target default.target
EOF

systemctl enable enable-linger.service





########## PODMAN serverless rootless



##
## Create a scale from zero systemd service for a container web
## server using socket activation
##

# create systemd user directories for rootless services, timers,
# and sockets
mkdir -p /var/home/ansible/.config/systemd/user/default.target.wants
mkdir -p /var/home/ansible/.config/systemd/user/sockets.target.wants
mkdir -p /var/home/ansible/.config/systemd/user/timers.target.wants
mkdir -p /var/home/ansible/.config/systemd/user/multi-user.target.wants



# define listener for socket activation
node_ip=$(ip a show dev $(ip route | grep default | awk '{print $5}') | grep "inet " | awk '{print $2}' | awk -F / '{print $1}')

cat << EOF > /var/home/ansible/.config/systemd/user/container-httpd-proxy.socket
[Socket]
ListenStream=${node_ip}:8080
FreeBind=true

[Install]
WantedBy=sockets.target
EOF



# define proxy service that launches web container and forwards
# requests to it
cat << EOF > /var/home/ansible/.config/systemd/user/container-httpd-proxy.service
[Unit]
Requires=container-httpd.service
After=container-httpd.service
Requires=container-httpd-proxy.socket
After=container-httpd-proxy.socket

[Service]
ExecStart=/usr/lib/systemd/systemd-socket-proxyd --exit-idle-time=10s 127.0.0.1:8080
EOF



##
## Create a service to launch the container workload and restart
## it on failure
##
cat > /var/home/ansible/.config/systemd/user/container-httpd.service <<EOF
# container-httpd.service
# autogenerated by Podman 3.0.2-dev
# Thu May 20 10:16:40 EDT 2021

[Unit]
Description=Podman container-httpd.service
Documentation=man:podman-generate-systemd(1)
Wants=network-online.target
After=network-online.target
RequiresMountsFor=%t/containers
StopWhenUnneeded=true

[Service]
Environment=PODMAN_SYSTEMD_UNIT=%n
Restart=on-failure
TimeoutStopSec=70
ExecStartPre=/bin/rm -f %t/%n.ctr-id
ExecStart=/usr/bin/podman run --cidfile %t/%n.ctr-id --cgroups=no-conmon --sdnotify=conmon -d --replace --name httpd --label io.containers.autoupdate=registry -p 127.0.0.1:8080:8080 {% raw %}{{ apps.app2.registry }}/{{ apps.app2.image }}:{{ apps.app1.prodtag }}{% endraw %}
ExecStop=/usr/bin/podman stop --ignore --cidfile=%t/%n.ctr-id
ExecStopPost=/usr/bin/podman rm -f --ignore --cidfile=%t/%n.ctr-id
Type=notify
NotifyAccess=all

[Install]
WantedBy=default.target
EOF





cat << EOF > /var/usrlocal/bin/pre-pull-container-image.sh
#!/bin/bash
while true; do
    if curl -s --head http://quay.io | grep "301" > /dev/null; then
        echo "Connectivity to http://quay.io established successfully."
        break
    else
        echo "Unable to connect to http://quay.io. Retrying in 10 seconds..."
        sleep 10
    fi
done
while true
do
  podman pull {% raw %}{{ apps.app2.registry }}/{{ apps.app2.image }}:{{ apps.app1.prodtag }}{% endraw %}
  podman image list | grep {% raw %}{{ apps.app2.image }}{% endraw %}
  if [ \$? -eq 0 ]
  then
    break
  fi
done
EOF

chmod +x /var/usrlocal/bin/pre-pull-container-image.sh

# pre-pull the container images at startup to avoid delay in http response
cat > /var/home/ansible/.config/systemd/user/pre-pull-container-image.service <<EOF
[Unit]
Description=Pre-pull container image service
After=network-online.target
Wants=network-online.target

[Service]
Type=oneshot
Restart=on-failure
RestartSec=10
TimeoutStartSec=30
ExecStart=/var/usrlocal/bin/pre-pull-container-image.sh

[Install]
WantedBy=multi-user.target default.target
EOF

# enable socket listener
ln -s /var/home/ansible/.config/systemd/user/container-httpd-proxy.socket /var/home/ansible/.config/systemd/user/sockets.target.wants/container-httpd-proxy.socket



# enable pre-pull container image
ln -s /var/home/ansible/.config/systemd/user/pre-pull-container-image.service /var/home/ansible/.config/systemd/user/default.target.wants/pre-pull-container-image.service
ln -s /var/home/ansible/.config/systemd/user/pre-pull-container-image.service /var/home/ansible/.config/systemd/user/multi-user.target.wants/pre-pull-container-image.service




# enable linger so user services run whether user logged in or not
cat << EOF > /etc/systemd/system/enable-linger.service
[Service]
Type=oneshot
ExecStart=loginctl enable-linger ansible

[Install]
WantedBy=multi-user.target default.target
EOF

systemctl enable enable-linger.service

# enable 8080 port through the firewall to expose the application
cat << EOF > /etc/systemd/system/expose-container-app2.service
[Unit]
Wants=firewalld.service
After=firewalld.service

[Service]
Type=oneshot
ExecStart=firewall-cmd --permanent --add-port=8080/tcp
ExecStartPost=firewall-cmd --reload

[Install]
WantedBy=multi-user.target default.target
EOF



systemctl enable expose-container-app2.service


# fix ownership of user local files and SELinux contexts
chown -R ansible: /var/home/ansible
restorecon -vFr /var/home/ansible






######## Greenboot

## This script is deployed by AAP but I keep it here in the KS for future reference

sudo cat << 'EOF' > /etc/greenboot/check/required.d/01-check-packages.sh
#!/bin/bash

if ! rpm -q python3-inotify &>/dev/null; then
  echo "Error: python3-inotify is not installed."
  exit 1
fi

echo "python3-inotify is installed."
EOF

chmod +x /etc/greenboot/check/required.d/01-check-packages.sh




## Disable the Microshift greenboot script for the demo.
##Sometimes greenboot fails on first boot in low BW environments and we want to keep logs clean
mv /etc/greenboot/check/required.d/40_microshift_running_check.sh /root





%end
