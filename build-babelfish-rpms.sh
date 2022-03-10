#!/bin/sh

# ----
# build-babelfish-rpms.sh
#
#	Shell script to build the Babelfish for PostgreSQL RPM files
#	inside of podman containers.
# ----

if [ $# -ne 1 ] ; then
    echo "usage: $(basename $0) CONFIGFILE" >&2
	echo "" >&2
	echo "example: $(basename $0) ./files/babelfishpg13/EL-8/build.conf" >&2
	echo "" >&2
	exit 2
fi

# Remember the current working directory
CURDIR="$(pwd)"
TMPDIR="$(pwd)/tmp"
CFGDIR="$(dirname $1)"

# Include the config file
source $1

# Location of the local git clone of repositories
BABELFISH_ENG_REPO="./babelfishpg_engine"
BABELFISH_EXT_REPO="./babelfishpg_extensions"

# Cleanup from previous builds
rm -rf RPMS
rm -rf "${TMPDIR}"
mkdir -p "${TMPDIR}"

# Download Antlr4 components on demand
ANTLR4_JAR="antlr-${ANTLR4_VERSION}-complete.jar"
ANTLR4_ZIP="antlr4-cpp-runtime-${ANTLR4_VERSION}-source.zip"
ANTLR4_JAR_URL="https://www.antlr.org/download/${ANTLR4_JAR}"
ANTLR4_ZIP_URL="https://www.antlr.org/download/${ANTLR4_ZIP}"
mkdir -p antlr4
if [ -f "./antlr4/${ANTLR4_JAR}" ] ; then
	echo "Using existing ./antlr4/${ANTLR4_JAR}"
else
	echo "Downloading ${ANTLR4_JAR_URL} as ./antlr4/${ANTLR4_JAR}"
	curl "${ANTLR4_JAR_URL}" --output "./antlr4/${ANTLR4_JAR}" || exit 1
fi
if [ -f "./antlr4/${ANTLR4_ZIP}" ] ; then
	echo "Using existing ./antlr4/${ANTLR4_ZIP}"
else
	echo "Downloading ${ANTLR4_ZIP_URL} as ./antlr4/${ANTLR4_ZIP}"
	curl "${ANTLR4_ZIP_URL}" --output "./antlr4/${ANTLR4_ZIP}" || exit 1
fi

# Create the source tarball for the Babelfish Engine
cd "${BABELFISH_ENG_REPO}" || exit 1
STASHID=$(git stash create)
if [ "$STASHID" != "" ] ; then
	BABELFISH_ENG_TAG=$STASHID
fi
echo "Creating Babelfish Engine tarball at $BABELFISH_ENG_TAG"
git archive --format=tar --prefix="${BABELFISH_ENG_PREFIX}/" \
	--output="${CURDIR}/tmp/${BABELFISH_ENG_PREFIX}.tar" \
	"${BABELFISH_ENG_TAG}" || exit 1
cd "${CURDIR}"

# Create the source tarball for the Babelfish Engine
cd "${BABELFISH_EXT_REPO}" || exit 1
STASHID=$(git stash create)
if [ "$STASHID" != "" ] ; then
	BABELFISH_EXT_TAG=$STASHID
fi
echo "Adding Babelfish Extensions at $BABELFISH_EXT_TAG"
for ext in common money tds tsql ; do
	git archive --format=tar --prefix="${BABELFISH_ENG_PREFIX}/" \
		--output="${CURDIR}/tmp/babelfishpg_${ext}.tar" \
		"${BABELFISH_EXT_TAG}" ./contrib/babelfishpg_${ext} || exit 1
done
cd "${CURDIR}/tmp"
for ext in common money tds tsql ; do
	tar --concatenate --file ${BABELFISH_ENG_PREFIX}.tar babelfishpg_${ext}.tar
	rm babelfishpg_${ext}.tar
done
echo "Compressing ${BABELFISH_ENG_PREFIX}.tar"
bzip2 "${BABELFISH_ENG_PREFIX}.tar" || exit 1
cd "${CURDIR}"

# Run rpmbuild for the first time to create the usual packages
podman build -t babelfishpg-eng-rpmbuild -f "${DOCKERFILE_ENG}" \
	--build-arg CFGDIR="${CFGDIR}" \
	--build-arg BABELFISH_ENG_PREFIX="${BABELFISH_ENG_PREFIX}" \
	. 2>&1 | tee podman-build-engine.log

# Create a container with that image and extract the Babelfish
# Engine RPMs from that. 
echo "Extracing RPM files"
mkdir RPMS || exit 1
id=$(podman create localhost/babelfishpg-eng-rpmbuild) || exit
podman cp "${id}:/root/rpmbuild/RPMS/." ./RPMS/ || exit
podman rm "${id}"

# Run rpmbuild a second time, now including the Babelfish Extensions.
# The container will install the RPMs built above so that the "old style"
# Babelfish Extensions build can find pg_config
podman build -t babelfishpg-ext-rpmbuild -f "${DOCKERFILE_EXT}" \
	--build-arg CFGDIR="${CFGDIR}" \
	--build-arg BABELFISH_ENG_PREFIX="${BABELFISH_ENG_PREFIX}" \
	--build-arg BABELFISH_EXT_PREFIX="${BABELFISH_EXT_PREFIX}" \
	--build-arg ANTLR4_JAR="${ANTLR4_JAR}" \
	--build-arg ANTLR4_ZIP="${ANTLR4_ZIP}" \
	. 2>&1 | tee podman-build-extensions.log

# Create a container with that and extract the extensions RPMS
echo "Extracing RPM files"
rm -rf RPMS
mkdir -p RPMS || exit 1
id=$(podman create localhost/babelfishpg-ext-rpmbuild) || exit 1
podman cp "${id}:/root/rpmbuild/RPMS/." ./RPMS/ || exit 1
podman rm "${id}"
echo ""
echo "RPMs built:"
ls -lhR --color=auto RPMS
