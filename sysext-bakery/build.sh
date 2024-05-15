#!/usr/bin/env bash
set -euo pipefail

echo "Building w3m sysext..."
CMD="apk -U add w3m" ./oci-rootfs.sh alpine:3.19.1 /tmp/alpine-w3m
# /etc provides terminfo files needed by w3m which are not available on the host, so we map /etc
# into the chroot:
ETCMAP="chroot" OS="_any" ARCH="" RELOAD="0" ./flatwrap.sh /tmp/alpine-w3m w3m /usr/bin/w3m
