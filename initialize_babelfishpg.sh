#!/bin/sh

# To be run as user postgres on the database host

PATH=/usr/pgsql-13/bin:$PATH
export PATH

initdb || exit 1

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

pg_ctl start || exit 1

psql -A postgres <<_EOF_
CREATE USER babelfish WITH CREATEDB CREATEROLE PASSWORD 'babel2';
CREATE DATABASE babelfish OWNER babelfish;
\c babelfish
CREATE EXTENSION babelfishpg_tds CASCADE;
CALL sys.initialize_babelfish('babelfish');
\q
_EOF_

pg_ctl stop
