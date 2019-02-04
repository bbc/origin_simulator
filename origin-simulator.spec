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

%description
origin_simulator is an elixir web app which responds
to HTTP requests in a predetermined way using recipes.
This RPM allows the loadtest package to be installed
on a Cosmos CentOS service.

%install
mkdir -p %{buildroot}/opt/origin_simulator
tar -C %{buildroot}/opt/origin_simulator -xzf %{SOURCE0}
mkdir -p %{buildroot}/usr/lib/systemd/system
cp %{SOURCE1} %{buildroot}/usr/lib/systemd/system/origin_simulator.service

%post
systemctl enable origin_simulator

%files
/opt/origin_simulator
/usr/lib/systemd/system/origin_simulator.service