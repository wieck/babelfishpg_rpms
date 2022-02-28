# These are macros to be used with find_lang and other stuff
%global packageversion 130
%global pgmajorversion 13
%global pgpackageversion 13
%global prevmajorversion 12
%global babelfishversion 1.1.0
%global pgversion 13.5
%global sname babelfishpg
%global pgname postgresql
%global pgbaseinstdir	/usr/pgsql-%{pgpackageversion}

%global beta 0
%{?beta:%global __os_install_post /usr/lib/rpm/brp-compress}

# Macros that define the configure parameters:
%{!?kerbdir:%global kerbdir "/usr"}
%{!?disablepgfts:%global disablepgfts 0}

%if 0%{?rhel} || 0%{?suse_version} >= 1315
%{!?enabletaptests:%global enabletaptests 0}
%else
%{!?enabletaptests:%global enabletaptests 1}
%endif

%{!?icu:%global icu 1}
%{!?kerberos:%global kerberos 1}
%{!?ldap:%global ldap 1}
%{!?nls:%global nls 1}
%{!?pam:%global pam 1}

# All Fedora releases now use Python3
# Support Python3 on RHEL 7.7+ natively
# RHEL 8 uses Python3
%{!?plpython3:%global plpython3 1}

%if 0%{?suse_version}
%if 0%{?suse_version} >= 1315
# Disable PL/Python 3 on SLES 12
%{!?plpython3:%global plpython3 0}
%endif
%endif

%{!?pltcl:%global pltcl 1}
%{!?plperl:%global plperl 1}
%{!?ssl:%global ssl 1}
%{!?test:%global test 1}
%{!?runselftest:%global runselftest 0}
%{!?uuid:%global uuid 1}
%{!?xml:%global xml 1}

%{!?systemd_enabled:%global systemd_enabled 1}

%ifarch ppc64 ppc64le s390 s390x armv7hl
%{!?sdt:%global sdt 0}
%else
 %{!?sdt:%global sdt 1}
%endif

# Turn off LLVM for Babelfish
# LLVM itself crashes when building babelfishpg_tsql
%if 0
%ifarch ppc64 ppc64le s390 s390x armv7hl
%if 0%{?rhel} && 0%{?rhel} == 7
%{!?llvm:%global llvm 0}
%else
%{!?llvm:%global llvm 1}
%endif
%else
%{!?llvm:%global llvm 1}
%endif
%else
%{!?llvm:%global llvm 0}
%endif

%{!?selinux:%global selinux 1}

%if 0%{?fedora} > 30
%global _hardened_build 1
%endif

%if 0%{?rhel} && 0%{?rhel} == 7
%ifarch ppc64 ppc64le
%pgdg_set_ppc64le_compiler_at10
%endif
%endif

Summary:	Babelfish Extension Package
Name:		%{sname}%{pgpackageversion}
Version:	%{babelfishversion}
Release:	1BABEL%{?dist}
License:	PostgreSQL
Url:		https://www.postgresql.org/

Source0:	%{sname}-extensions-%{babelfishversion}-PG-%{pgversion}.tar.bz2

Patch1:		%{sname}%{pgmajorversion}-extensions.patch

BuildRequires:	perl glibc-devel bison flex >= 2.5.31
BuildRequires:	perl(ExtUtils::MakeMaker)
BuildRequires:	readline-devel zlib-devel >= 1.0.4 pgdg-srpm-macros

# This dependency is needed for Source 16:
%if 0%{?fedora} || 0%{?rhel} > 7
BuildRequires:	perl-generators
%endif

%if 0%{?rhel} && 0%{?rhel} == 7
%ifarch ppc64 ppc64le
%pgdg_set_ppc64le_min_requires
%endif
%endif

Requires:	/sbin/ldconfig

%if %icu
BuildRequires:	libicu-devel
Requires:	libicu
%endif

%if %llvm
%if 0%{?rhel} && 0%{?rhel} == 7
# Packages come from EPEL and SCL:
%ifarch aarch64
BuildRequires:	llvm-toolset-7.0-llvm-devel >= 7.0.1 llvm-toolset-7.0-clang >= 7.0.1
%else
BuildRequires:	llvm5.0-devel >= 5.0 llvm-toolset-7-clang >= 4.0.1
%endif
%endif
%if 0%{?rhel} && 0%{?rhel} >= 8
# Packages come from Appstream:
BuildRequires:	llvm-devel >= 8.0.1 clang-devel >= 8.0.1
%endif
%if 0%{?fedora}
BuildRequires:	llvm-devel >= 5.0 clang-devel >= 5.0
%endif
%if 0%{?suse_version} >= 1315 && 0%{?suse_version} <= 1499
BuildRequires:	llvm6-devel clang6-devel
%endif
%if 0%{?suse_version} >= 1500
BuildRequires:	llvm11-devel clang11-devel
%endif
%endif

%if %kerberos
BuildRequires:	krb5-devel
BuildRequires:	e2fsprogs-devel
%endif

%if %ldap
%if 0%{?suse_version}
%if 0%{?suse_version} >= 1315
BuildRequires:	openldap2-devel
%endif
%else
BuildRequires:	openldap-devel
%endif
%endif

%if %nls
BuildRequires:	gettext >= 0.10.35
%endif

%if %pam
BuildRequires:	pam-devel
%endif

%if %plperl
%if 0%{?rhel} && 0%{?rhel} >= 7
BuildRequires:	perl-ExtUtils-Embed
%endif
%if 0%{?fedora} >= 22
BuildRequires:	perl-ExtUtils-Embed
%endif
%endif

%if %plpython3
BuildRequires:	python3-devel
%endif

%if %pltcl
BuildRequires:	tcl-devel
%endif

%if %sdt
BuildRequires:	systemtap-sdt-devel
%endif

%if %selinux
# All supported distros have libselinux-devel package:
BuildRequires:	libselinux-devel >= 2.0.93
# SLES: SLES 15 does not have selinux-policy package. Use
# it only on SLES 12:
%if 0%{?suse_version} >= 1315 && 0%{?suse_version} <= 1499
BuildRequires:	selinux-policy >= 3.9.13
%endif
# RHEL/Fedora has selinux-policy:
%if 0%{?rhel} || 0%{?fedora}
BuildRequires:	selinux-policy >= 3.9.13
%endif
%endif

%if %ssl
# We depend un the SSL libraries provided by Advance Toolchain on PPC,
# so use openssl-devel only on other platforms:
%ifnarch ppc64 ppc64le
%if 0%{?suse_version} >= 1315 && 0%{?suse_version} <= 1499
BuildRequires:	libopenssl-devel
%else
BuildRequires:	openssl-devel
%endif
%endif
%endif

%if %uuid
%if 0%{?suse_version}
%if 0%{?suse_version} >= 1315
BuildRequires:	uuid-devel
%endif
%else
BuildRequires:	libuuid-devel
%endif
%endif

%if %xml
BuildRequires:	libxml2-devel libxslt-devel
%endif

%if %{systemd_enabled}
BuildRequires:		systemd, systemd-devel
# We require this to be present for %%{_prefix}/lib/tmpfiles.d
Requires:		systemd
%if 0%{?suse_version}
%if 0%{?suse_version} >= 1315
Requires(post):		systemd-sysvinit
%endif
%else
Requires(post):		systemd-sysv
Requires(post):		systemd
Requires(preun):	systemd
Requires(postun):	systemd
%endif
%else
Requires(post):		chkconfig
Requires(preun):	chkconfig
# This is for /sbin/service
Requires(preun):	initscripts
Requires(postun):	initscripts
%endif

Requires:	%{name}-libs%{?_isa} = %{version}-%{release}

Requires(post):	%{_sbindir}/update-alternatives
Requires(postun):	%{_sbindir}/update-alternatives

Provides:	%{sname} >= %{version}-%{release}

%description
Babelfish for PostgreSQL is a fork of PostgreSQL with limited
SQL-Server support.

%package babelextensions
Summary:	The Babelfish Extension Modules
Requires:	%{name}%{?_isa} = %{version}-%{release}
Requires:	%{name}-libs%{?_isa} = %{version}-%{release}
Requires:	%{name}-server%{?_isa} = %{version}-%{release}
Provides:	postgresql-babelfish-extensions >= %{version}-%{release}

%if 0%{?rhel} && 0%{?rhel} == 7
%ifarch ppc64 ppc64le
AutoReq:	0
Requires:	advance-toolchain-%{atstring}-runtime
%endif
%endif

%description babelextensions
The Babelfish for PostgreSQL extension modules babelfishpg_money,
babelfishpg_common, babelfishpg_tds and babelfishpg_tsql.

%prep
%setup -q -n %{sname}-extensions-%{babelfishversion}-PG-%{pgversion}
%patch1 -p1

%build

PG_CONFIG="%{pgbaseinstdir}/bin/pg_config"
PG_SRC="/root/tmp/%{sname}-engine-%{babelfishversion}-PG-%{pgversion}"
cmake="/usr/bin/cmake"
export PG_CONFIG PG_SRC cmake

%{__make} -C contrib/babelfishpg_money
%{__make} -C contrib/babelfishpg_common
%{__make} -C contrib/babelfishpg_tds
%{__make} -C contrib/babelfishpg_tsql

%install
%{__rm} -rf %{buildroot}

PG_CONFIG="%{pgbaseinstdir}/bin/pg_config"
PG_SRC="/root/tmp/%{sname}-engine-%{babelfishversion}-PG-%{pgversion}"
cmake="/usr/bin/cmake"
export PG_CONFIG PG_SRC cmake

%{__make} -C contrib/babelfishpg_money DESTDIR=%{buildroot} install
%{__make} -C contrib/babelfishpg_common DESTDIR=%{buildroot} install
%{__make} -C contrib/babelfishpg_tds DESTDIR=%{buildroot} install
%{__make} -C contrib/babelfishpg_tsql DESTDIR=%{buildroot} install

%{__cp} /usr/local/lib/libantlr4-runtime.so.* %{buildroot}%{pgbaseinstdir}/lib/

%clean
%{__rm} -rf %{buildroot}

# FILES section.

%files babelextensions
%defattr(-,root,root)
%{pgbaseinstdir}/lib/libantlr4*
%{pgbaseinstdir}/lib/babelfishpg*
%{pgbaseinstdir}/share/extension/babelfishpg*
%{pgbaseinstdir}/share/extension/fixeddecimal--1.0.0--1.1.0.sql
