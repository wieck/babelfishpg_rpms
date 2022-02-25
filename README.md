babelfishpg_rpms
================

**WARNING**: This is for discussion only at this point!

This is a set of files and scripts to build AWS Babelfish
for PostgreSQL binary RPM packages via Podman.

The spec and patch files used to build the engine were copied
from git://git.postgresql.org/git/pgrpms.git, then changed
to reflect the build needs of Babelfish.

Building RPMS
-------------

The build process currently only covers the usual RPMs you
get from building community PostgreSQL, i.e. the Engine part
of Babelfish. 

Run
```
cd ./babelfishpg_rpms
git submodul update --init
./build-babelfish-engine-rpms.sh ./files/babelfishpg13/EL-8/bulid.conf
```
