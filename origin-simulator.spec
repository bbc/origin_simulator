Name: origin-simulator
Version: %{cosmos_version}
Release: 1%{?dist}
License: MPL-2.0
Group: Development/Frameworks
URL: https://github.com/bbc/origin_simulator
Summary: Simulates a non perfect downstream service
Packager: BBC News Frameworks and Tools

Source0: /root/rpmbuild/SOURCES/origin_simulator.tar.gz
Source1: /root/rpmbuild/SOURCES/origin_simulator.service
Source2: /root/rpmbuild/SOURCES/performance.conf

BuildRoot: %{_tmppath}/%{name}-%{version}-%{release}-root
BuildArch: x86_64

Requires: erlang

%description
origin_simulator is an elixir web app which responds
to HTTP requests in a predetermined way using recipes.
This RPM allows the loadtest package to be installed
on a Cosmos CentOS service.

%pre
/usr/bin/getent group component >/dev/null || groupadd -r component
/usr/bin/getent passwd component >/dev/null || useradd -r -g component -G component -s /sbin/nologin -c 'component service' component

%install
mkdir -p %{buildroot}
mkdir -p %{buildroot}/etc/sysctl.d
mkdir -p %{buildroot}/etc/security/limits.d
mkdir -p %{buildroot}/home/component
mkdir -p %{buildroot}/home/component/origin_simulator
tar -C %{buildroot}/home/component/origin_simulator -xzf %{SOURCE0}
mkdir -p %{buildroot}/usr/lib/systemd/system
cp %{SOURCE1} %{buildroot}/usr/lib/systemd/system/origin_simulator.service
cp %{SOURCE2} %{buildroot}/etc/sysctl.d/performance.conf

%post
systemctl enable origin_simulator
/bin/chown -R component:component /home/component

%files
/home/component
/usr/lib/systemd/system/origin_simulator.service
/etc/sysctl.d/performance.conf
