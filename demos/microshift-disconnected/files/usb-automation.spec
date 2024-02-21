# Define metadata for the package
Name: usb-automation
Version: 1.0
Release: 1
Summary: Adds scripts to make the usb-based automation work
BuildArch: x86_64
License: GPL

# Define dependencies (if any)
Requires: systemd

%description
Adds scripts to make the usb-based automation work

%prep
# No preparation needed

%install
rm -rf $RPM_BUILD_ROOT
mkdir -p $RPM_BUILD_ROOT/etc/udev/rules.d/
mkdir -p $RPM_BUILD_ROOT/usr/local/etc/
mkdir -p $RPM_BUILD_ROOT/usr/local/bin/
mkdir -p $RPM_BUILD_ROOT/etc/systemd/system
cp -p /root/usb-automation/99-usb-autoconfig.rules $RPM_BUILD_ROOT/etc/udev/rules.d/
cp -p /root/usb-automation/rhde_automation_encryption_key $RPM_BUILD_ROOT/usr/local/etc/
cp -p /root/usb-automation/rhde-automation-pub.pem $RPM_BUILD_ROOT/usr/local/etc/
cp -p /root/usb-automation/usb-autoconfig.service $RPM_BUILD_ROOT/etc/systemd/system/
cp -p /root/usb-automation/signature_verification_script.sh $RPM_BUILD_ROOT/usr/local/bin/
cp -p /root/usb-automation/usb_autoconfig.sh $RPM_BUILD_ROOT/usr/local/bin/
cp -p /root/usb-automation/rhde_automation_run.sh $RPM_BUILD_ROOT/usr/local/bin/
cp -p /root/usb-automation/usb_check.sh $RPM_BUILD_ROOT/usr/local/bin/
chmod +x $RPM_BUILD_ROOT/usr/local/bin/*
# Set SELinux context for the files
restorecon -R $RPM_BUILD_ROOT/etc/systemd/system $RPM_BUILD_ROOT/usr/local/bin/  $RPM_BUILD_ROOT/etc/udev/rules.d/ $RPM_BUILD_ROOT/usr/local/etc/
# Reload systemd daemon
systemctl daemon-reload
# Restart systemd-udevd service
systemctl restart systemd-udevd.service

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

%changelog
