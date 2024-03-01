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

mkdir -p $RPM_BUILD_ROOT/%{_prefix}/etc/gdm/
mkdir -p $RPM_BUILD_ROOT/var/lib/AccountsService/users/
mkdir -p $RPM_BUILD_ROOT/var/home/admin/.local/bin/

cp -p /root/kiosk-automation/rhde_encrypted.tar $RPM_BUILD_ROOT/%{_prefix}/share/
cp -p /root/kiosk-automation/kiosk-token.container $RPM_BUILD_ROOT/%{_prefix}/share/containers/systemd/
cp -p /root/kiosk-automation/gdm-custom.conf $RPM_BUILD_ROOT/%{_prefix}/etc/gdm/custom.conf
cp -p /root/kiosk-automation/admin-accountservice $RPM_BUILD_ROOT/var/lib/AccountsService/users/admin
cp -p /root/kiosk-automation/gnome-kiosk-script $RPM_BUILD_ROOT/var/home/admin/.local/bin/gnome-kiosk-script
systemctl daemon-reload

# Define files to be included in the package
%files
/%{_prefix}/share/rhde_encrypted.tar
/%{_prefix}/share/containers/systemd/kiosk-token.container
/%{_prefix}/etc/gdm/custom.conf
/var/lib/AccountsService/users/admin
/var/home/admin/.local/bin/gnome-kiosk-script

%changelog
