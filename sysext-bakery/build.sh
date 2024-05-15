#!/usr/bin/env bash
set -euo pipefail

echo "Building w3m sysext..."
CMD="apk -U add w3m" ./oci-rootfs.sh docker.io/library/alpine:3.19.1 /tmp/alpine-w3m
OS="_any" ARCH="" RELOAD="0" ./flatwrap.sh /tmp/alpine-w3m w3m /usr/bin/w3m
ls
