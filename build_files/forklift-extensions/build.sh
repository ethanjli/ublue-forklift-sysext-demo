#!/bin/sh

set -ouex pipefail

RELEASE="$(rpm -E %fedora)"
ARCH="$(arch)"

### Install a terminal multiplexer to help with any troubleshooting:

rpm-ostree install screen

### Install Forklift:

FORKLIFT_VERSION="0.7.0-alpha.3"
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
