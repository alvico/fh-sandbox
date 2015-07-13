#!/bin/sh
dpkg -i /override/midonet-api_1.9.3~rc1_all.deb
dpkg -i /override/python-midonetclient_1.9.3~rc1_all.deb.deb
sed -i -e "s/org.midonet.api.auth.keystone.v2_0.KeystoneService/org.midonet.cluster.auth.MockAuthService/g" /usr/share/midonet-api/WEB-INF/web.xml
/run-midonetapi.sh
