#!/bin/sh

podman image rm localhost/babelfishpg-eng-rpmbuild
podman image rm localhost/babelfishpg-ext-rpmbuild
podman system prune -f
