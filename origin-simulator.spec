Name: mozart-loadtest
Version: %{cosmosversion}
Release: 1%{?dist}
License: MPL-2.0
Group: Development/Frameworks
URL: https://github.com/bbc/origin_simulator
Summary: Simulates a non perfect downstream service
Packager: BBC News Frameworks and Tools

Source0: origin_simulator.tar.gz

BuildRoot: %{_tmppath}/%{name}-%{version}-%{release}-root
BuildArch: x86_64

Requires: erlang

%description
origin_simulator is an elixir web app which responds
to HTTP requests in a predetermined way using recipes.
This RPM allows the loadtest package to be installed
on a Cosmos CentOS service.
TODO: add a systemctl unit file to start the service

%install
tar -C %{buildroot}/opt/origin_simulator -xzf %{SOURCE0}


%files
/opt/origin_simulator