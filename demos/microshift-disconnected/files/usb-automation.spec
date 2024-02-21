# Define metadata for the package
Name: usb-automation
Version: 1.0
Release: 1
Summary:        Adds scripts to make the usb-based automation work

# Define dependencies (if any)
Requires: systemd

# Define files to be included in the package
%files
/etc/udev/rules.d/99-usb-autoconfig.rules
/usr/local/bin/signature_verification_script.sh
/usr/local/bin/usb_autoconfig.sh
/usr/local/bin/rhde_automation_run.sh
/etc/systemd/system/usb-autoconfig.service
/usr/local/bin/usb_check.sh
/usr/local/etc/rhde_automation_encryption_key
/usr/local/etc/rhde-automation-pub.pem


# Define post-installation scriptlet
%post
cp %{_sourcedir}/99-usb-autoconfig.rules /etc/udev/rules.d/
cp %{_sourcedir}/rhde_automation_encryption_key /usr/local/etc/
cp %{_sourcedir}/rhde-automation-pub.pem /usr/local/etc/
cp %{_sourcedir}/usb-autoconfig.service /etc/systemd/system/
cp %{_sourcedir}/signature_verification_script.sh /usr/local/bin/
cp %{_sourcedir}/usb_autoconfig.sh /usr/local/bin/
cp %{_sourcedir}/rhde_automation_run.sh /usr/local/bin/
cp %{_sourcedir}/usb_check.sh /usr/local/bin/
chmod +x /usr/local/bin/*
# Set SELinux context for the files
restorecon -R /usr/local/bin/  /etc/udev/rules.d/ /usr/local/etc/
# Reload systemd daemon
systemctl daemon-reload
# Restart systemd-udevd service
systemctl restart systemd-udevd.service
