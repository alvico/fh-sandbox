#!/bin/sh
dpkg -i /override/midolman_1.9.3~rc1_all.deb

sysctl -w net.ipv6.conf.all.disable_ipv6=1
sysctl -w net.ipv6.conf.default.disable_ipv6=1
sysctl -w net.ipv6.conf.lo.disable_ipv6=1

/run-midolman.sh
