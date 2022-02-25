# ----
# postgresql-babelfish 13.5 RPM build
#
# We build this on CentOS-Stream 8 for now ... should switch to Rocky
# ----
FROM rockylinux:8

# Build arguments passed from the build script
ARG CFGDIR
ARG BABELFISH_ENG_PREFIX

# Adjust NCPUS to what your max. Note that values above 16
# don't work without modifying rpmmacros
ENV HOME=/root
ENV RPM_BUILD_NCPUS=16

# Add the EPEL and PGDG RPM repositories
RUN dnf install -y epel-release
RUN dnf install -y https://download.postgresql.org/pub/repos/yum/reporpms/EL-8-x86_64/pgdg-redhat-repo-latest.noarch.rpm

# Install all build dependencies
RUN dnf install -y \
	bison \
	clang-devel \
	e2fsprogs-devel \
	flex \
	gettext \
	git \
	glibc-devel \
	krb5-devel \
	libicu-devel \
	libselinux-devel \
	libuuid-devel \
	libxml2-devel \
	libxslt-devel \
	llvm-devel \
	openldap-devel \
	openssl-devel \
	pam-devel \
	perl \
	perl-ExtUtils-Embed \
	perl-ExtUtils-MakeMaker \
	perl-generators \
	pgdg-srpm-macros \
	python3-devel \
	readline-devel \
	rpm-build \
	selinux-policy \
	systemd-devel \
	systemtap-sdt-devel \
	tcl-devel \
	zlib-devel

# Copy RPM spec and SOURCES
COPY "./tmp/$BABELFISH_ENG_PREFIX.tar.bz2" /root/rpmbuild/SOURCES/
COPY "$CFGDIR/SOURCES/" /root/rpmbuild/SOURCES
COPY "$CFGDIR/babelfishpg13.spec" /root/

# Run rpmbuild
RUN	cd /root \
	&& rpmbuild -bb babelfishpg13.spec
