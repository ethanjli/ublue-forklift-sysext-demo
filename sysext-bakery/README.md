# sysext-bakery: Recipes for baking systemd-sysext images

This directory uses scripts from
[github.com/flatcar/sysext-bakery](https://github.com/flatcar/sysext-bakery) to build some
experimental system extension images in OCI container images, for use with
[github.com/ethanjli/ublue-forklift-sysext-demo](https://github.com/ethanjli/ublue-forklift-sysext-demo/).

## Licensing

The `flatwrap.sh`, and `oci-rootfs.sh` scripts in this directory were copied verbatim
from Apache-2.0-licensed files with the same names written by [@pothos](https://github.com/pothos)
and downloaded from
[flatcar/sysext-bakery e3534d3](https://github.com/flatcar/sysext-bakery/commit/e3534d3).
The `oci-rootfs.sh` script was also modified to enable compatibility with a wider variety of
container images (this change will be submitted as an upstream PR after testing).
The `bake.sh` script in this directory was copied verbatim
from the Apache-2.0-licensed file with the same name written by [@pothos](https://github.com/pothos)
and downloaded from
[flatcar/sysext-bakery d1419fc](https://github.com/flatcar/sysext-bakery/commit/d1419fc).
