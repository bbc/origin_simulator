#!/bin/bash

echo "1000000" > /proc/sys/ds/file-max
echo "1000000" > /proc/sys/ds/file-max

sysctl -w net.ipv4.ip_local_port_range="1025 65535"

cat << EOF >> /etc/security/limits.conf
# <domain> <type> <item>  <value>
    *       soft  nofile  900000
    *       hard  nofile  900000
EOF
