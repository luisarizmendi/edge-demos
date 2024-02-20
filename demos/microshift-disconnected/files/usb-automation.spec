


**********


sudo systemctl daemon-reload
sudo service systemd-udevd --full-restart


*********













Name:           usb-automation
Version:        0.0.1
Release:        1%{?dist}
Summary:        Adds scripts to make the usb-based automation work
BuildArch:      noarch
License:        GPL
# No Source0 directive needed if directly using local files

%description
Adds scripts to make the usb-based automation work

%prep
# No preparation needed

%install
rm -rf $RPM_BUILD_ROOT
mkdir -p $RPM_BUILD_ROOT/%{_prefix}/lib/microshift/manifests
# Copy manifest files from /root/manifests
cp -pr /root/manifests/* $RPM_BUILD_ROOT/%{_prefix}/lib/microshift/manifests/

%files
%{_prefix}/lib/microshift/manifests/**

%changelog