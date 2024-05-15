#!/usr/bin/env bash
set -euo pipefail

mkdir -p build

echo "Building neovim sysext as .raw image..."
CMD="apk -U add neovim neovim-doc" ./oci-rootfs.sh alpine:3.19.1 /tmp/alpine-neovim
OS="_any" ARCH="" RELOAD="0" ./flatwrap.sh /tmp/alpine-neovim neovim /usr/bin/nvim
# TODO: make flatwrap keep the files around in the build directory so that we can copy them into a
# container
