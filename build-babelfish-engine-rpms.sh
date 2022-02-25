#!/bin/sh

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
echo "Creating Babelfish Engine tarball"
cd "${BABELFISH_ENG_REPO}" || exit 1
git archive --format=tar --prefix="${BABELFISH_ENG_PREFIX}/" \
	--output="${CURDIR}/tmp/${BABELFISH_ENG_PREFIX}.tar" \
	"${BABELFISH_ENG_TAG}" || exit 1
cd "${CURDIR}/tmp"
bzip2 "${BABELFISH_ENG_PREFIX}.tar" || exit 1
cd "${CURDIR}"

# Create the source tarball for the Babelfish Engine
echo "Creating Babelfish Extensions tarball"
cd "${BABELFISH_EXT_REPO}" || exit 1
git archive --format=tar --prefix="${BABELFISH_EXT_PREFIX}/" \
	--output="${CURDIR}/tmp/${BABELFISH_EXT_PREFIX}.tar" \
	"${BABELFISH_EXT_TAG}" || exit 1
cd "${CURDIR}/tmp"
bzip2 "${BABELFISH_EXT_PREFIX}.tar" || exit 1
cd "${CURDIR}"

# Now it is time to actually run the rpmbuild inside a docker image build.
podman build -t babelfishpg-rpmbuild -f "${DOCKERFILE_ENG}" \
	--build-arg CFGDIR="${CFGDIR}" \
	--build-arg BABELFISH_ENG_PREFIX="${BABELFISH_ENG_PREFIX}" \
	. 2>&1 | tee podman-build-engine.log || exit 1

# Finally create a container and extract the RPM files.
echo "Extracing RPM files"
mkdir RPMS || exit 1
id=$(podman create localhost/babelfishpg-rpmbuild)
podman cp "${id}:/root/rpmbuild/RPMS/." ./RPMS/
podman rm "${id}"
ls -lhR --color=auto RPMS
