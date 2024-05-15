#!/usr/bin/env bash
set -euo pipefail

echo "Building neovim sysext..."
CMD="apk -U add neovim neovim-doc" ./oci-rootfs.sh alpine:3.19.1 /tmp/alpine-neovim
OS="_any" ARCH="" RELOAD="0" ./flatwrap.sh /tmp/alpine-neovim neovim /usr/bin/nvim

echo "Building go sysext..."
REGISTRY="cgr.dev" ./oci-rootfs.sh chainguard/go:latest /tmp/wolfi-go
OS="_any" ARCH="" RELOAD="0" ./flatwrap.sh /tmp/wolfi-go go /usr/lib/go/bin/go:/usr/bin/go /usr/lib/go/bin/gofmt:/usr/bin/gofmt
