#!/usr/bin/env bash
set -euo pipefail

echo "Building neovim sysext..."
CMD="apk -U add neovim neovim-doc" ./oci-rootfs.sh alpine:3.19.1 /tmp/alpine-neovim
OS="_any" ARCH="" RELOAD="0" ./flatwrap.sh /tmp/alpine-neovim neovim /usr/bin/nvim

echo "Building bluefin-cli sysext..."
CMD="" ./oci-rootfs.sh ghcr.io/ublue-os/bluefin-cli:latest /tmp/wolfi-bluefin-cli
OS="_any" ARCH="" RELOAD="0" ./flatwrap.sh /tmp/wolfi-bluefin-cli bluefin-cli /usr/bin/atuin /usr/bin/delta /usr/bin/gawk /usr/bin/eza /usr/bin/fd /usr/bin/fish /usr/bin/fzf /usr/bin/rclone /usr/bin/ripgrep /usr/bin/sed /usr/bin/starship /usr/bin/zoxide /bin/zsh:/usr/bin/zsh /usr/share/bash-prexec:/usr/sharepbash-prexec
