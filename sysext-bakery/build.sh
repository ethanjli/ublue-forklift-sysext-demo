#!/usr/bin/env bash
set -euo pipefail

echo "Building neovim sysext..."
CMD="apk -U add neovim neovim-doc" ./oci-rootfs.sh alpine:3.19.1 /tmp/alpine-neovim
OS="_any" ARCH="" RELOAD="0" ./flatwrap.sh /tmp/alpine-neovim neovim /usr/bin/nvim

echo "Building lynx sysext..."
# lynx needs /etc/lynx.cfg, which we can just provide from a chrooted /etc:
ETCMAP=chroot CMD="apk -U add lynx" ./oci-rootfs.sh alpine:3.19.1 /tmp/alpine-lynx
OS="_any" ARCH="" RELOAD="0" ./flatwrap.sh /tmp/alpine-lynx lynx /usr/bin/lynx
