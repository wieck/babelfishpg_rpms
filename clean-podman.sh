#!/bin/sh

buildah rm -a
podman image rm localhost/babelfishpg-eng-rpmbuild
podman system prune -f
