#!/usr/bin/env bash
set -euo pipefail

echo "Building neovim sysext..."
CMD="apk -U add neovim" ./oci-rootfs.sh alpine:3.19.1 /tmp/alpine-neovim
OS="_any" ARCH="" RELOAD="0" ./flatwrap.sh /tmp/alpine-neovim neovim /usr/bin/nvim
