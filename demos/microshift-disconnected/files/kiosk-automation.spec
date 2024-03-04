# Define metadata for the package
Name: kiosk-automation
Version: 1.0
Release: 1
Summary: Adds scripts to make the kiosk-based automation work
BuildArch: x86_64
License: GPL

# Define dependencies (if any)
Requires: systemd

%description
Adds scripts to make the kiosk-based automation work

%prep
# No preparation needed

%install
rm -rf $RPM_BUILD_ROOT
mkdir -p $RPM_BUILD_ROOT/%{_prefix}/share/containers/systemd/
mkdir -p $RPM_BUILD_ROOT/%{_prefix}/bin/
mkdir -p $RPM_BUILD_ROOT/etc/systemd/system

cp -p /root/kiosk-automation/rhde_encrypted.tar $RPM_BUILD_ROOT/%{_prefix}/share/
cp -p /root/kiosk-automation/kiosk-token.container $RPM_BUILD_ROOT/%{_prefix}/share/containers/systemd/
cp -p /root/kiosk-automation/config_kiosk.sh $RPM_BUILD_ROOT/%{_prefix}/bin/config_kiosk.sh
cp -p /root/kiosk-automation/kiosk-config.service $RPM_BUILD_ROOT/etc/systemd/system/kiosk-config.service
cp -p /root/kiosk-automation/config_kiosk.sh $RPM_BUILD_ROOT/%{_prefix}/bin/deactivation_kiosk.sh
cp -p /root/kiosk-automation/deactivation-kiosk.service $RPM_BUILD_ROOT/etc/systemd/system/deactivation-kiosk.service

chmod +x $RPM_BUILD_ROOT/%{_prefix}/bin/config_kiosk.sh
chmod +x $RPM_BUILD_ROOT/%{_prefix}/bin/deactivation_kiosk.sh

# Reload systemd daemon
systemctl daemon-reload

# Define files to be included in the package
%files
/%{_prefix}/share/rhde_encrypted.tar
/%{_prefix}/share/containers/systemd/kiosk-token.container
/%{_prefix}/bin/config_kiosk.sh
/%{_prefix}/bin/deactivation_kiosk.sh
/etc/systemd/system/kiosk-config.service
/etc/systemd/system/deactivation-kiosk.service

%changelog
