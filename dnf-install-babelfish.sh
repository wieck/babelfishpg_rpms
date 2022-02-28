#!/bin/sh

# To be run as user root on the database host
# after creating the babelfishpg RPM repository

dnf install -y \
	babelfishpg13-libs \
	babelfishpg13 \
	babelfishpg13-server \
	babelfishpg13-contrib \
	babelfishpg13-babelextensions
