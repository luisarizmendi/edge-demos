#!/bin/bash

cat <<EOF > /etc/gdm/custom.conf
# GDM configuration storage

[daemon]
# Uncomment the line below to force the login screen to use Xorg
#WaylandEnable=false
AutomaticLoginEnable=True
AutomaticLogin=admin

[security]

[xdmcp]

[chooser]

[debug]
# Uncomment the line below to turn on debugging
#Enable=true
EOF
# Check if cat command was successful
if [ $? -ne 0 ]; then
    echo "Error: Failed to create the file."
    exit 1
fi


cat <<EOF > /var/lib/AccountsService/users/admin
# This file contains defaults for new users. To edit, first
# copy it to /etc/accountsservice/user-templates and make changes
# there

[com.redhat.AccountsServiceUser.System]
id='"rhel"'
version-id='"9.3"'

[User]
Session=gnome-kiosk-script
Icon=/home/admin/.face
SystemAccount=false
EOF
# Check if cat command was successful
if [ $? -ne 0 ]; then
    echo "Error: Failed to create the file."
    exit 1
fi

mkdir -p /var/home/admin/.local/bin/
chmod -R 0755 /var/home/admin/.local

cat <<EOF > /var/home/admin/.local/bin/gnome-kiosk-script
#!/bin/sh

kiosk_page="http://localhost:8080"

while true; do
	/usr/bin/curl -o /dev/null \$kiosk_page 2> /dev/null
	rc=\$?

	if [ "\$rc" == "0" ]; then
        /usr/bin/firefox --kiosk \$kiosk_page --display=:0
	else
		sleep 1
	fi
done
EOF

# Check if cat command was successful
if [ $? -ne 0 ]; then
    echo "Error: Failed to create the file."
    exit 1
fi

chmod 0755 /var/home/admin/.local/bin/gnome-kiosk-script
chown admin /var/home/admin/.local/bin/gnome-kiosk-script

systemctl restart gdm.service
# Check if cat command was successful
if [ $? -ne 0 ]; then
    echo "Error: Failed to create the file."
    exit 1
fi



