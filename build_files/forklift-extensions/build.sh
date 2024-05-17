#!/bin/sh

set -ouex pipefail

RELEASE="$(rpm -E %fedora)"
ARCH="$(arch)"

### Install a terminal multiplexer to help with any troubleshooting:

rpm-ostree install screen

### Install Forklift:

FORKLIFT_VERSION="0.7.2-alpha.6"
# Do we need any other substitutions? We use goreleaser's defaults (e.g. `arm64` for 64-bit ARM, and
# `arm` for armv7); it probably doesn't matter because for now ublue only has amd64 builds:
FORKLIFT_ARCH="$(echo "$ARCH" | sed -e 's/x86_64/amd64/')"
curl -L "https://github.com/PlanktoScope/forklift/releases/download/v$FORKLIFT_VERSION/forklift_${FORKLIFT_VERSION}_linux_${FORKLIFT_ARCH}.tar.gz" \
  | sudo tar -C /usr/bin -xz forklift
sudo mv /usr/bin/forklift "/usr/bin/forklift-${FORKLIFT_VERSION}"
sudo ln -s "forklift-${FORKLIFT_VERSION}" /usr/bin/forklift

### Integrate Forklift with systemd-sysext for sysexts & confexts:

systemctl enable forklift-stage-apply-systemd.service

echo "Done with Forklift setup!"

### (purely for demo) Allow use of sysexts built by Flatcar Container Linux's sysext-bakery
# Note: this rewrites the `/usr/lib/os-release` file to pretend to match the host OS requirements
# declared by `extension-release` files in the system extension images built/released in Flatcar
# Container Linux's sysext-bakery. You should not do this on a real system; instead, you'll need to
# fork sysext-bakery and re-build all the system extension images with `extension-release` files
# which are compatible with your host OS!
sed -i '/^ID/s/fedora/flatcar/' /usr/lib/os-release
echo "SYSEXT_LEVEL=1.0" >> /usr/lib/os-release
