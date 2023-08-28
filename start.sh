#!/bin/bash

export LC_ALL=C
/etc/init.d/postgresql start
/opt/solr-8.11.2/bin/solr start -force
/opt/tomcat/bin/startup.sh
/usr/sbin/sshd -D