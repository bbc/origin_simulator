Name: mozart-loadtest
Version: %{cosmosversion}
Release: 1%{?dist}
License: MPL-2.0
Group: Development/Frameworks
URL: https://github.com/bbc/origin_simulator
Summary: Simulates a non perfect downstream service
Packager: BBC News Frameworks and Tools

Source0: origin_simulator.tar.gz
Source1: origin_simulator.service

BuildRoot: %{_tmppath}/%{name}-%{version}-%{release}-root
BuildArch: x86_64

Requires: erlang
Requires: belfrage-performance-tuning

%description
origin_simulator is an elixir web app which responds
to HTTP requests in a predetermined way using recipes.
This RPM allows the loadtest package to be installed
on a Cosmos CentOS service.

%pre
/usr/bin/getent group component >/dev/null || groupadd -r component
/usr/bin/getent passwd component >/dev/null || useradd -r -g component -G component -s /sbin/nologin -c 'component service' component
/usr/bin/chsh -s /bin/bash component

%install
mkdir -p %{buildroot}/home/component
mkdir -p %{buildroot}/home/component/origin_simulator
tar -C %{buildroot}/home/component/origin_simulator -xzf %{SOURCE0}
mkdir -p %{buildroot}/usr/lib/systemd/system
cp %{SOURCE1} %{buildroot}/usr/lib/systemd/system/origin_simulator.service

%post
systemctl enable origin_simulator
/bin/chown -R component:component /home/component

%files
/home/component
/usr/lib/systemd/system/origin_simulator.service
