babelfishpg_rpms
================

**NOTE: This is for discussion only at this point! The names
of repositories and which version numbers are used where may
change in the final release.**

This repository is a set of files and scripts to build **Babelfish
for PostgreSQL** binary RPM packages via docker/podman.

The spec and patch files used to build the engine were taken
from git://git.postgresql.org/git/pgrpms.git, then changed
to reflect the build needs of Babelfish.

Overview
--------

This repository provides scripts, configuration files and patches
to build binary RPM files of **Babelfish for PostgreSQL**. 

In this **first version for discussion** the only build target is
branch BABEL_1_X_DEV__PG_13_6 of the main engine (repository
`postgresql_modified_for_babelfish`) and branch BABEL_1_X_DEV of
the extensions (repository `babelfish_extensions)
on RedHat EL-8 systems (like CentOS and
Rocky Linux). The directory structure of config and patch files is
however set up to support other OS and Babelfish versions in the
future.

The entire process works as follows:

* [Preparing the build environment](#preparing-the-build-environment)
* [Running the build script](#running-the-build-script)
* [Creating a local RPM repository](#creating-a-local-RPM-repository)
  on the target host
* [Installing Babelfish](#installing-babelfish) from the RPM repository
  on the target host
* [Creating the Babelfish cluster](#creating-the-babelfish-cluster)
* [Testing connectivity](#testing-connectivity)

Preparing the build environment
----------------------------

The only tools needed on the build host are git, tar, bzip2 and
podman. Everything else is happening in a docker/podman container,
so the host environment is rather irrelevant. To install the tools
run
```
sudo dnf install -y git tar bzip2 podman
```

Next we need to clone this repository as well as the
postgresql_modified_for_babelfish repository.

**NOTE: Currently the following uses clone repositories that have open pull
requests needed for all of this to work. This will be fixed once
those PRs are merged.**
```
cd $HOME
git clone https://github.com/wieck/postgresql_modified_for_babelfish.git
cd postgresql_modified_for_babelfish
git submodule update --init
cd ..
git clone https://github.com/wieck/babelfishpg_rpms.git
```

Running the build script
------------------------

The build script `build-babelfish-rpms.sh` takes one argument, the
path to a config file that specifies version numbers, path prefixes
and git tags to be used.

```
cd $HOME/babelfishpg_rpms
./build-babelfish-rpms.sh ./files/babelfishpg13/EL-8/build.conf
```

The build script will perform the following actions:

* Download the [Antlr4](https://www.antlr.org/) jar archive and sources
  for the runtime (needed by the babelfishpg_tsql extension) into
  *./antlr4/*. The version of Antlr4 to use is
  specified in the config file (./files/babelfishpg13/EL-8/build.conf).
  This is only done if the download files don't exist.

* Create the `babelfishpg13 tarball` file of the postgresql_modified_for_babelfish
  repository cloned above in `tmp`. This is the
  source tarball to be used later by the `rpmbuild` commamd
  inside the docker/podman container. The git tags to use are specified
  in the config file.

* Run `podman build` with the *Dockerfile.engine* found in the same
  directory as the config file. This will create a docker/podman image
  by setting up a Rocky Linux based build environment,
  copying the tarballs and all support files (scripts, PG config files
  and patches) into the build container, then run `rpmbuild` with the
  *babelfishpg13-engine.spec* file (also found in the config file's
  directory).

* Create a container based on that image, extract the built RPM files
  into *./RPMS* and delete the container.

The end result should look similar to this:
```
$ ls -lhR RPMS
RPMS:
total 4.0K
drwxr-xr-x 2 wieck wieck 4.0K Feb 27 22:08 x86_64

RPMS/x86_64:
total 42M
-rw-r--r-- 1 wieck wieck 1.5M Feb 27 21:29 babelfishpg13-1.1.0-1BABEL.el8.x86_64.rpm
-rw-r--r-- 1 wieck wieck 2.0M Feb 27 22:08 babelfishpg13-babelextensions-1.1.0-1BABEL.el8.x86_64.rpm
-rw-r--r-- 1 wieck wieck 7.1M Feb 27 22:08 babelfishpg13-babelextensions-debuginfo-1.1.0-1BABEL.el8.x86_64.rpm
-rw-r--r-- 1 wieck wieck 640K Feb 27 21:30 babelfishpg13-contrib-1.1.0-1BABEL.el8.x86_64.rpm
-rw-r--r-- 1 wieck wieck 1.7M Feb 27 21:30 babelfishpg13-contrib-debuginfo-1.1.0-1BABEL.el8.x86_64.rpm
-rw-r--r-- 1 wieck wieck 1.4M Feb 27 21:30 babelfishpg13-debuginfo-1.1.0-1BABEL.el8.x86_64.rpm
-rw-r--r-- 1 wieck wieck 1.5M Feb 27 22:08 babelfishpg13-debugsource-1.1.0-1BABEL.el8.x86_64.rpm
-rw-r--r-- 1 wieck wieck 2.4M Feb 27 21:30 babelfishpg13-devel-1.1.0-1BABEL.el8.x86_64.rpm
-rw-r--r-- 1 wieck wieck 241K Feb 27 21:30 babelfishpg13-devel-debuginfo-1.1.0-1BABEL.el8.x86_64.rpm
-rw-r--r-- 1 wieck wieck 4.3M Feb 27 21:30 babelfishpg13-docs-1.1.0-1BABEL.el8.x86_64.rpm
-rw-r--r-- 1 wieck wieck 415K Feb 27 21:29 babelfishpg13-libs-1.1.0-1BABEL.el8.x86_64.rpm
-rw-r--r-- 1 wieck wieck 458K Feb 27 21:30 babelfishpg13-libs-debuginfo-1.1.0-1BABEL.el8.x86_64.rpm
-rw-r--r-- 1 wieck wieck  72K Feb 27 21:30 babelfishpg13-plperl-1.1.0-1BABEL.el8.x86_64.rpm
-rw-r--r-- 1 wieck wieck 152K Feb 27 21:30 babelfishpg13-plperl-debuginfo-1.1.0-1BABEL.el8.x86_64.rpm
-rw-r--r-- 1 wieck wieck  99K Feb 27 21:30 babelfishpg13-plpython3-1.1.0-1BABEL.el8.x86_64.rpm
-rw-r--r-- 1 wieck wieck 174K Feb 27 21:30 babelfishpg13-plpython3-debuginfo-1.1.0-1BABEL.el8.x86_64.rpm
-rw-r--r-- 1 wieck wieck  45K Feb 27 21:30 babelfishpg13-pltcl-1.1.0-1BABEL.el8.x86_64.rpm
-rw-r--r-- 1 wieck wieck  99K Feb 27 21:30 babelfishpg13-pltcl-debuginfo-1.1.0-1BABEL.el8.x86_64.rpm
-rw-r--r-- 1 wieck wieck 5.6M Feb 27 21:29 babelfishpg13-server-1.1.0-1BABEL.el8.x86_64.rpm
-rw-r--r-- 1 wieck wieck  11M Feb 27 21:30 babelfishpg13-server-debuginfo-1.1.0-1BABEL.el8.x86_64.rpm
-rw-r--r-- 1 wieck wieck 2.0M Feb 27 21:30 babelfishpg13-test-1.1.0-1BABEL.el8.x86_64.rpm
-rw-r--r-- 1 wieck wieck  74K Feb 27 21:30 babelfishpg13-test-debuginfo-1.1.0-1BABEL.el8.x86_64.rpm
```

Creating a local RPM repository
-------------------------------

The RPM files created above can be installed with the `rpm(8)` program.
But that is no fun as one has to install all dependencies by hand too.
It is far more convenient to create a local repository and use the `dnf(8)`
utility to install Babelfish.

Setting up a proper, WEB server based repository with SSL support and
GPG checking is totally out of the scope of this document. But we can
set up a local, file based repository relatively easy. First we create
the repository itself by running

```
sudo dnf install -y createrepo
sudo mkdir -p /usr/local/share/babelfishpg/$(uname -m)
sudo cp RPMS/$(uname -m)/* /usr/local/share/babelfishpg/$(uname -m)
sudo createrepo /usr/local/share/babelfishpg/$(uname -m)
```

We also need a *.repo* file in */etc/yum.repos.d* to let `dnf(8)` know
about this new repo. A file */etc/yum.repos.d/babelfishpg.repo* with the
content
```
[babelfishpg]
name=Babelfish for PostgreSQL
baseurl=file:///usr/local/share/babelfishpg/$basearch
enabled=1
gpgcheck=0
```
will do that. There is a script `build-babelfish-repo.sh` in the root
directory of the *babelfishpg_rpms* git repo that assumes one has
authorized_keys based root-ssh to the actual target DB servers. It takes
a list of hostnames and installs this file based RPM repo on all of them.

Quick check that all of that worked so far:
```
[root@pghost ~]# dnf search babelfish
Last metadata expiration check: 0:02:35 ago on Sun 27 Feb 2022 10:29:17 PM EST.
=================================================================== Name & Summary Matched: babelfish ====================================================================
babelfishpg13-babelextensions.x86_64 : The Babelfish Extension Modules
babelfishpg13-babelextensions-debuginfo.x86_64 : Debug information for package babelfishpg13-babelextensions
babelfishpg13-contrib-debuginfo.x86_64 : Debug information for package babelfishpg13-contrib
babelfishpg13-debuginfo.x86_64 : Debug information for package babelfishpg13
babelfishpg13-debugsource.x86_64 : Debug sources for package babelfishpg13
babelfishpg13-devel-debuginfo.x86_64 : Debug information for package babelfishpg13-devel
babelfishpg13-libs-debuginfo.x86_64 : Debug information for package babelfishpg13-libs
babelfishpg13-plperl-debuginfo.x86_64 : Debug information for package babelfishpg13-plperl
babelfishpg13-plpython3-debuginfo.x86_64 : Debug information for package babelfishpg13-plpython3
babelfishpg13-pltcl-debuginfo.x86_64 : Debug information for package babelfishpg13-pltcl
babelfishpg13-server-debuginfo.x86_64 : Debug information for package babelfishpg13-server
babelfishpg13-test-debuginfo.x86_64 : Debug information for package babelfishpg13-test
======================================================================== Name Matched: babelfish =========================================================================
babelfishpg13.x86_64 : PostgreSQL client programs and libraries
babelfishpg13-contrib.x86_64 : Contributed source and binaries distributed with PostgreSQL
babelfishpg13-devel.x86_64 : PostgreSQL development header files and libraries
babelfishpg13-docs.x86_64 : Extra documentation for PostgreSQL
babelfishpg13-libs.x86_64 : The shared libraries required for any PostgreSQL clients
babelfishpg13-plperl.x86_64 : The Perl procedural language for PostgreSQL
babelfishpg13-plpython3.x86_64 : The Python3 procedural language for PostgreSQL
babelfishpg13-pltcl.x86_64 : The Tcl procedural language for PostgreSQL
babelfishpg13-server.x86_64 : The programs needed to create and run a PostgreSQL server
babelfishpg13-test.x86_64 : The test suite distributed with PostgreSQL
```

Looks pretty good to me.

Installing Babelfish
--------------------

**NOTE: If you previously installed postgresql13 packages on this host
they need to be uninstalled first.**

Installing **Babelfish for PostgreSQL** from the file based repository
is fairly simple from here. All we have to do is to copy the
*/usr/local/share/babelfishpg* directory and
*/etc/yum.repos.d/babelfishpg.repo* file to a RedHat 8 based host
(or use the *build-babelfish-repo.sh* script to do the job)
and run
```
dnf install -y \
    babelfishpg13-libs \
    babelfishpg13 \
    babelfishpg13-server \
    babelfishpg13-contrib \
    babelfishpg13-babelextensions
```
on that host.

This will install those **Babelfish for PostgreSQL** components plus a
good number of Perl, libicu, libxslt and the like dependencies.
Those are the exact same dependencies that would get pulled in if you
installed community *postgresql13-...* instead.

Creating the Babelfish Cluster
------------------------------

All that is left is to actually initialize the data directory *$PGDATA*
and create our **Babelfish for PostgreSQL** database.

On the target database host (where we installed the
*babelfishpg13-...* packages) we need to run
```
sudo su - postgres

PATH=/usr/pgsql-13/bin:$PATH
export PATH

initdb

echo ""
echo "Creating $PGDATA/postgresql.auto.conf"
cat >/$PGDATA/postgresql.auto.conf <<_EOF_
listen_addresses = '*'
max_connections = 256
shared_buffers = 16GB
work_mem = 16MB
maintenance_work_mem = 64MB
wal_level = logical
checkpoint_timeout = 10min
max_wal_size = 64GB
min_wal_size = 16GB
checkpoint_completion_target = 0.9
checkpoint_warning = 5min
tcp_keepalives_idle = 57
tcp_keepalives_interval = 7
tcp_keepalives_count = 9
shared_preload_libraries = 'babelfishpg_tds'
babelfishpg_tsql.database_name = 'babelfish'
babelfishpg_tsql.migration_mode = 'multi-db'
babelfishpg_tds.tds_debug_log_level = 0
_EOF_

echo "Adding private networks to $PGDATA/pg_hba.conf"
cat >>$PGDATA/pg_hba.conf <<_EOF_
# Private networks
host all all 10.0.0.0/8 md5
host all all 172.16.0.0/12 md5
host all all 192.168.0.0/16 md5
_EOF_
echo ""

pg_ctl start

psql -A postgres <<_EOF_
CREATE USER babelfish WITH CREATEDB CREATEROLE PASSWORD 'babel2';
CREATE DATABASE babelfish OWNER babelfish;
\c babelfish
CREATE EXTENSION babelfishpg_tds CASCADE;
CALL sys.initialize_babelfish('babelfish');
\q
_EOF_

pg_ctl stop
```
This will
* Initialize $PGDATA,
* add necessary, Babelfish specific configuration options as if
  the Postgres Superuser had run 'ALTER SYSTEM' commands,
* allow **unencrypted** connections from all private networks
  (you may need to adjust this to your actual network topology),
* start the postmaster process (for now),
* create a user *babelfish* with the necessary credentials,
* create the *babelfish* default database,
* create the Babelfish extension and dependencies inside the database,
* initialize the TSQL specific system objects
* and shut down the postmaster process.

Finally we need to configure the Babelfish service to start at system
boot time and allow outside systems to connect to it
```
sudo systemctl enable postgresql-13
sudo systemctl start postgresql-13
sudo firewall-cmd --zone public --add-port 5432/tcp
sudo firewall-cmd --zone public --add-port 1433/tcp
sudo firewall-cmd --runtime-to-permanent
```

Testing Connectivity
--------------------

At this point we want to see if our **Babelfish for PostgreSQL**
installation is speaking TDS protocol on port 1433/TCP. For that we
need some sort of native SQL-Server client program.

I am just going to use *SQLCMD* for that. Note that you will need version
17 or *mssql-tools* and *msodbcsql*. The current version 18 will refuse
to connect as Babelfish currently does not support encryption of the TDS
Login handshake. The installation procedure for that is documented
[here](https://docs.microsoft.com/en-us/sql/connect/odbc/linux-mac/installing-the-microsoft-odbc-driver-for-sql-server?view=sql-server-ver15#17).
```
$ sqlcmd -S mybabelhost -U babelfish -P babel2
1> select version();
2> go
version
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
Babelfish for PostgreSQL with SQL Server Compatibility - 12.0.2000.8
Mar 24 2022 17:30:05
Copyright (c) Amazon Web Services
PostgreSQL 13.6 Babelfish for PostgreSQL on x86_64-pc-linux-gnu

(1 rows affected)
1>
```
