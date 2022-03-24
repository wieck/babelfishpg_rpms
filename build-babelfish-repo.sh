#!/bin/sh

if [ $# -lt 1 ] ; then
	echo "usage: $(basename $0) HOST [...]" >&2
	exit 2
fi

BASEURL=/usr/local/share/babelfishpg/$(uname -m)

for host in $@ ; do
	ssh root@$host dnf install -y createrepo
	ssh root@$host mkdir -p ${BASEURL}
	scp RPMS/$(uname -m)/* root@$host:${BASEURL}/
	ssh root@$host createrepo ${BASEURL}
	ssh root@$host cat \>/etc/yum.repos.d/babelfishpg.repo <<_EOF_
[babelfishpg]
name=Babelfish for PostgreSQL
baseurl=file:///usr/local/share/babelfishpg/\$basearch
enabled=1
gpgcheck=0
_EOF_
done
