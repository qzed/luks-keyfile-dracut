%global dracut_modules_d /usr/lib/dracut/modules.d
%global dracut_conf_d /etc/dracut.conf.d

Name:       luks-keyfile-dracut
Version:    1.0.0
Release:    1%{?dist}
Summary:    Unlock LUKS partition during boot via key file on partition

License:    GPLv3
BuildArch:  noarch
Requires:   dracut

%description
Unlock LUKS partition during boot via key file on partition

%install
mkdir -p %{buildroot}/%{dracut_conf_d}/
mkdir -p %{buildroot}/%{dracut_modules_d}/
cp luks-keyfile-dracut/dracut.conf.d/luks-keyfile.conf %{buildroot}/%{dracut_conf_d}/
cp -r luks-keyfile-dracut/96luks-keyfile %{buildroot}/%{dracut_modules_d}/

%post
dracut -fv

%postun
dracut -fv

%files
%{dracut_conf_d}/luks-keyfile.conf
%{dracut_modules_d}/96luks-keyfile

%changelog
* Sat Feb 15 2020 Maximilian Luz <luzmaximilian@gmail.com>
- Initial release
