# ublue-forklift-sysext-demo

A simple demo of using Forklift to distribute & manage sysexts in a Fedora OSTree-based system

# Introduction

This repository provides bootable OS container images (and corresponding installer ISOs) for a
simple [ublue](https://universal-blue.org/)-based demo for integrating
[Forklift](https://github.com/PlanktoScope/forklift) with
[systemd-sysext](https://www.freedesktop.org/software/systemd/man/latest/systemd-sysext.html)
in a Fedora OSTree-based system. You should not use the images provided by this repository for
anything serious!

# Usage

(the guide below refers to terms specific to Forklift; if you get confused, you can jump down to the
[Explanation](#explanation) section to read a long summary of what those terms mean)

## Set up your VM

You will need to download the latest version of the installer ISO. To do so, go to
<https://github.com/ethanjli/ublue-forklift-sysext-demo/actions/workflows/build-base.yml> (for a
CLI-only OS image) or
<https://github.com/ethanjli/ublue-forklift-sysext-demo/actions/workflows/build-bluefin.yml> (for an
OS image with a GNOME desktop), click on the most recent workflow run which was triggered by the
`main` branch (not any feature branches! the OS images built from feature branches are
works-in-progress which are probably broken in various ways) and which completed successfully, and
download the `ublue-forklift-sysext-demo-latest.zip` or
`ublue-forklift-sysext-demo-bluefin-latest.zip` artifact from it; the download should be ~3 GB. The
ZIP archive contains the installer ISO file; you should extract the ISO file, create a new VM with
it, and proceed through the installer.

After you finish installation, restart the VM, and log in, then you should run
(**without** `sudo`!):

```
just-setup-forklift-staging
```

That command will enable you to run `forklift pallet switch` (or `forklift pallet stage`) commands
(described below) without having to use `sudo -E` and without having to set
`FORKLIFT_STAGE_STORE=/var/lib/forklift/stages` as an environment variable for those commands.

## Use a pallet

This VM image comes without a Forklift pallet on your first boot, so that you can learn how to use a
pallet. This guide will use the pallet at the latest commit from the `main` branch of
[github.com/ethanjli/pallet-example-exports](https://github.com/ethanjli/pallet-example-exports)
and apply it to your VM in order to add a few sysexts+confexts to your VM, but you can make
your own pallet and use it instead.

To clone and stage the pallet, just run:

```
forklift pallet switch github.com/ethanjli/pallet-example-exports@main
```

(Note: if you hate typing, then you can replace `pallet` with `plt` - that's three entire keypresses
saved!!)

If you run `systemd-sysext status`, you can confirm that there are not yet any sysexts on your
system. You can also confirm that the `docker`, `dive`, `crane`, `nvim`, and `go` commands do not
exist yet, by trying to run those commands. You can also confirm that the "JetBrains Mono" fonts
do not exist yet, by looking for it in the list of system fonts when trying to set a custom
font in the Ptyxis terminal (Ptyxis is available if you're using the Bluefin-based OS image provided
by this repo).

Next, you should reboot (or if you're *really* impatient and don't want to reboot, run
`sudo forklift-stage-apply-systemd`).

Next, you should then see new system extensions if you run `systemd-sysext status`. You should also
see that:

- A new service named `hello-world-extension` ran successfully, if you check its status with
  `systemctl status hello-world-extension.service`; and a script at
  `/usr/bin/hello-world-extension` now exists. This script and this systemd service are provided by
  the `hello-world` extension exported by the Forklift pallet
  `github.com/ethanjli/pallet-example-exports`.
- The `docker` systemd service is now running, if you check its status with
  `systemctl status docker.service`.
- If you run `sudo docker image pull alpine:latest` and `sudo docker image ls`, you will have pulled
  the Docker container image for `alpine:latest`; similarly, you can use Docker however you want.
- If you run `sudo dive alpine:latest`, you can use [dive](https://github.com/wagoodman/dive)
  to browse/inspect the contents/structure of the `alpine:latest` Docker container image.
- If you run `crane export alpine:latest - | tar -tvf - | less`, you can use
  [crane](https://github.com/google/go-containerregistry/blob/main/cmd/crane/README.md)
  to list the files in the `alpine:latest` Docker container image.
- If you run `nvim`, you can use [neovim](https://github.com/neovim/neovim); furthermore, if you
  enter the `:help nvim` command, you will see help text which is only available because the
  system extension which provides neovim via
  [an Alpine Linux package](https://pkgs.alpinelinux.org/package/edge/community/x86_64/neovim)
  also includes the
  [neovim-doc package](https://pkgs.alpinelinux.org/package/edge/community/x86_64/neovim-doc). And
  if you run `readelf -a /usr/local/neovim/usr/bin/nvim | grep -i musl`, you can see that `nvim`
  was compiled for use with musl rather than glibc.
- If you open the Ptyxis terminal settings (assuming you're using the Bluefin-based OS image
  provided by this repo) and open the window to set a custom font, you will see the "JetBrains Mono"
  fonts appear in the font selection window.

You can switch to another pallet from GitHub/GitLab/etc. using the `forklift pallet switch` command;
it will totally replace the contents of `~/.local/share/forklift/pallet` and create a new staged
pallet bundle in the stage store (which is at both `~/.local/share/forklift/stages` and
`/var/lib/forklift/stages`). Each time you run `forklift pallet switch` or `forklift pallet stage`,
`forklift` will create a new staged pallet bundle in the stage store. You can query and modify the
state of your stage store by running `forklift stage show` and by running other subcommands of
`forklift stage`; if you just run `forklift stage`, it will print some information about the
available subcommands.

## Modify a pallet and use it

You can edit your local copy of the pallet, which is at `~/.local/share/forklift/pallet`, either
using the Forklift CLI or by directly editing YAML files in your local copy of the pallet; after
making changes, you can stage (and apply) the modified pallet.
Warning: if you have changes in your local pallet which you haven't pushed up to
GitHub/etc. and then you run `forklift pallet switch {pallet-path}@{version-query}`, your
modifications to your pallet will all be deleted/overwritten and replaced with the pallet you're
switching to! If you are thinking of doing that, you should first commit and push your changes to
GitHub/GitLab/etc. to prevent permanent loss of your changes.

### With the Forklift CLI

To modify your local copy of the pallet, you can use various subcommands of `forklift plt`, e.g.:

- To disable the `dive` package deployment (which makes the `dive` sysext available to systemd), you
  can run `forklift plt disable-depl dive`. To re-enable the package deployment, you can run
  `forklift plt enable-depl dive`.
- To disable the `service` feature flag (which provides a confext to enable `docker.service` as part
  of systemd's service startup process) in the `docker` package deployment, you can run
  `forklift plt disable-depl-feat docker service`. To re-enable the feature flag, you can run
  `forklift plt enable-depl-feat docker service`.

Instead of running these subcommands and then running `forklift plt stage` to stage your modified
pallet, you can enable an optional `--stage` flag in these subcommands to immediately stage the
pallet after modifying the pallet. For example, you can run
`forklift plt disable-depl --stage dive` and reboot, after which the `dive` sysext will no longer be
available to systemd. So you can think of `forklift plt enable-depl --stage` and
`forklift plt disable-depl --stage` as the rough (but more verbose) equivalents of
`systemctl enable` and `systemctl disable`.

### By editing YAML files

Alternatively, you can directly edit files in `~/.local/share/forklift/pallet` and then run
`forklift plt stage` and reboot (or run `sudo forklift-stage-apply-systemd` to preview your
changes).

For example, to disable the `dive` sysext, add the line `disabled: true` to
`~/.local/share/forklift/pallet/deployments/dive.deploy.yml`, run
`forklift plt stage`, and reboot (or run `sudo forklift-stage-apply-systemd`); then `dive` will no
longer be available on your system.

# Explanation

## What is Forklift?

Forklift is an experimental prototype tool primarily designed to make it simpler to build OS images
(esp. custom images) of non-atomic Linux distros which need to provide a set of Docker Compose apps
and/or a custom layer of any OS files (where the specific directories to layer should be decided by
the maintainer of the custom OS image, not by Forklift); and to enable users/operators to quickly &
cleanly upgrade/downgrade/reprovision their deployment of those Docker Compose apps and OS files
without having to re-install the custom OS image. Currently Forklift is designed/developed/tested
mainly for the Raspberry Pi OS-based
[operating system of a specific hardware project](https://docs-edge.planktoscope.community/reference/software/architecture/os/)
which is currently still tied to an older version of Raspberry Pi OS (bullseye) with a pre-sysext
version of systemd. But since sysext images are also just OS files, we can repurpose Forklift to
deploy a particular set of sysext images (according to a configuration specified for Forklift) onto
the OS.

In Forklift, OS files (and Docker Compose apps, but we don't care about them for this demo) are
modularized into *Forklift packages*; a package is just a directory which contains a special
`forklift-package.yml` file and which is somewhere inside a *Forklift repository*, which is just a
Git repository with a special `forklift-repository.yml` file at the root of the repository. A
package can declare some files within the package's directory which should be made available at some
declared paths in a special *export directory* (more on this later). Forklift packages and
repositories are roughly analogous to [Go packages and modules](https://go.dev/ref/mod),
respectively - except that Forklift packages/repositories cannot "import" or "include" other
Forklift packages/repositories, and the path of the Forklift repository must be exactly the path of
its Git repository (e.g. `github.com/ethanjli/example-exports` is valid, but
`github.com/ethanjli/example-exports/v2` and `github.com/ethanjli/forklift-demos/example-exports`
are not valid repository paths); these differences from the design of Go Modules keep Forklift's
design simpler for Forklift's specific use-case.

## What is a "pallet"?

Forklift packages cannot be deployed/installed on their own. Instead, we create a *Forklift pallet*
to declare the complete configuration of all Forklift packages which should be deployed on a
computer. A pallet is just a Git repository with a special `forklift-pallet.yml` file at the root
of the repository, and some other special files in a special directory structure. We can then use
Forklift or Git to clone the pallet to our computer, and then we can use Forklift to *stage* the
pallet to be applied to our computer. When Forklift stages a pallet, it copies various files into
a new directory called a *staged pallet bundle* (look,, naming is hard; I welcome suggestions for
better names) in a special directory called the *stage store* (again, please help me come up with a
better name). Inside the staged pallet bundle is a subdirectory called `exports` which contains all
the files declared for export by the pallet's deployed packages.

We can add a systemd service which runs during early boot (e.g. before `sysinit.target` or
`local-fs.target`) and queries Forklift for the path of the staged pallet bundle which should be
applied to the computer, and then bind-mounts or overlay-mounts or symlinks-to a subdirectory in
that bundle's `exports` subdirectory for an arbitrary path on the filesystem, e.g. `/usr` or `/etc`
or `/var/lib/extensions` or whatever you're interested in. Then we can add a systemd service which
refreshes systemd's view of systemd units/sysexts/confexts/etc. The demo in this repository sets up
a read-only bind-mount between
`/var/lib/forklift/stages/{id of the staged pallet bundle to apply}/exports/extensions` and
`/var/lib/extensions` (and likewise for `/var/lib/confexts`) and refreshes systemd afterwards.

## What does `forklift pallet switch` do?

The `forklift pallet switch` command is intended to feel roughly familiar/intuitive to people who
also use `bootc switch` and/or `rpm-ostree rebase`. Behind-the-scenes, running
`forklift pallet switch {path of pallet}@{version query}` will:

1. Clone the pallet as a Git repository to a local copy at `~/.local/share/forklift/pallet`, and
   check out the latest commit of the `main` branch; if anything was previously at
   `~/.local/share/forklift/pallet`, it's deleted beforehand (note: I recently modified Forklift to
   delete `~/.local/share/forklift/pallet/.git` after cloning, but I plan to revert that behavior).
   This step can also be run on its own with
   `forklift pallet clone --force {path of pallet}@{version query}`.
2. Download any external Forklift repositories required by the pallet into
   `~/.cache/forklift/repositories`.
   This step can also be run on its own with `forklift pallet cache-repo`.
3. Run some checks to ensure that the pallet is valid, e.g. that deployed packages don't conflict
   with each other.
   This step can also be run on its own with `forklift pallet check`.
4. Stage the pallet to be used on the next reboot, by creating a new staged pallet bundle in
   `~/.local/share/forklift/stages` (which, in this OS image, is attached to
   `/var/lib/forklift/stages` via a bind-mount created by the `just-setup-forklift-staging` script).
   This step can also be run on its own with `forklift pallet stage`.

## What does the `forklift-stage-apply-systemd` script do?

This script is run by the `forklift-stage-apply-systemd.service` systemd service as part of early
(or early-ish) boot every time the OS boots up. It will:

1. Query Forklift to determine the path of the next staged pallet bundle to be applied. This path
   will be a subdirectory of `/var/lib/forklift/stages`.
2. Mount (or re-mount) that staged pallet bundle's `exports/extensions` subdirectory to
   `/var/lib/extensions`.
3. Mount (or re-mount) that staged pallet bundle's `exports/extensions` subdirectory to
   `/var/lib/confexts`.
4. Run `systemd-sysext refresh`.
5. Run `systemctl daemon-reload`.
6. Run `systemctl restart --no-block sockets.target timers.target multi-user.target default.target`.
   Warning: if you run `forklift-stage-apply-systemd` after boot, this will not attempt to stop any
   systemd units associated with sysexts/confexts which you've removed after boot. This is why I
   generally recommend just rebooting instead of running `forklift-stage-apply-systemd` yourself.
7. Run `forklift stage apply` to update the deployed Docker Compose apps (only if there are any, and
   only if `/var/run/docker.sock` exists), and record in Forklift's stage store that the staged
   pallet bundle was successfully applied so that it won't be garbage-collected if you run
   `forklift stage prune-bundles` to clean up Forklift's stage store)
   (Note: I still need to implement some functionality in Forklift to handle the case that Docker
   is not installed, so for now you should just avoid running `forklift stage prune-bundles` unless
   you want to delete everything in your stage store).

## Where do `docker`, `dive`, etc., come from?

### `docker`

The `github.com/ethanjli/pallet-example-exports` pallet is configured to download the Docker system
extension image provided by
[Flatcar Container Linux's sysext-bakery](https://github.com/flatcar/sysext-bakery/releases/tag/latest)
and make it available to systemd-sysext; the pallet also adds a `docker-service-enablement`
sysext & confext which enables the `docker.service` unit provided by the Docker sysext, and which
prepares the host so that it can run Docker (namely, adding a `docker` group so that `docker.socket`
will work).

### `dive`

By contrast,
[`dive`](https://github.com/wagoodman/dive) does not have an associated pre-built system extension
image. Instead, the `github.com/ethanjli/pallet-example-exports` pallet is configured to download
the amd64 binary from [GitHub Releases](https://github.com/wagoodman/dive/releases) and make it
available to systemd-sysext as part of a system extension directory assembled and exported by
Forklift.

### `crane`

Unlike `dive`,
[`crane`](https://github.com/google/go-containerregistry/blob/main/cmd/crane/README.md)
has an associated multi-arch Docker container image maintained by Chainguard at
[cgr.dev/chainguard/crane](https://images.chainguard.dev/directory/image/crane/versions). The
`github.com/ethanjli/pallet-example-exports` pallet is configured to extract the binary from either
the `amd64` or `arm64` container image (which is automatically selected depending on the CPU
architecture target of the `forklift` tool) and make it available to systemd-sysext as part of a
system extension directory assembled and exported by Forklift.

### Neovim

Unlike `docker`, `dive`, and `crane`, [`nvim`](https://github.com/neovim/neovim) is not available as
a statically-linked binary - so it depends on system libraries (for example, trying to run the
binaries from [Neovim's GitHub Releases](https://github.com/neovim/neovim/releases) on Alpine Linux
will not work due to the lack of glibc; instead, Alpine Linux's package for Neovim needs to be
installed to use Neovim on Alpine Linux). This repository includes a GitHub
Actions workflow to automatically build a multi-arch container image which includes a `.raw` system
extension image file with `nvim`, using
[oci-rootfs](https://github.com/flatcar/sysext-bakery/blob/main/oci-rootfs.sh) and
[flatwrap](https://github.com/flatcar/sysext-bakery/blob/main/flatwrap.sh) with
[Alpine Linux's neovim package](https://pkgs.alpinelinux.org/package/edge/community/x86/neovim)
(which is linked against musl) to make `nvim` work without any problems as a sysext on glibc-based
systems. The `github.com/ethanjli/pallet-example-exports` pallet is configured to extract the `.raw`
system extension image from either the `amd64` or `arm64` version of the resulting multi-arch
container image (with the architecture automatically selected depending on the CPU architecture
target of the `forklift` tool) and make it available to systemd-sysext.

# Caveats/Limitations

Hacks/workarounds:

- This demo disables SELinux policy enforcement because of
  <https://github.com/systemd/systemd/issues/23971> /
  <https://github.com/systemd/systemd/issues/31404#issuecomment-1973478641>, and because I don't
  have enough experience with SELinux to change the SELinux policy so that the overlays don't cause
  everything (e.g. sudo and chkpwd) to break after systemd-sysext enables filesystem overlays (or
  maybe it's the bind mounts I make in this demo for Forklift?), and because this is just a demo. If
  someone can fix the SELinux policies for this demo, please submit a pull request at
  <https://github.com/ethanjli/ublue-forklift-sysext-demo/pulls>!
- Because Flatcar's Docker system extension images are built to only be used on hosts whose
  `/usr/lib/os-release` files include `ID=flatcar` and `SYSEXT_LEVEL=1.0`, the bootable OS container
  images built by this repository lie that their OS ID is `flatcar` instead of `fedora` (even though
  they are still just Fedora Linux). Yes, rewriting the os-release file's distro ID is a massive
  hack; in my defense, I don't want to maintain my own fork of Flatcar's sysext-bakery just for a
  demo. If/when the Universal Blue project starts releasing their own sysext images
  at <https://github.com/ublue-os/sysext>, I will use those instead of Flatcar's sysext images.
- Docker requires a mutable `/etc` in order to correctly set up firewall rules with
  firewalld/iptables, but systemd 256 (which is supposed to make it possible to have a mutable
  `/etc` even when confexts are active) has not been released yet. As a temporary workaround, this
  repo uses Forklift to make a mutable overlay for `/etc` over the confexts; however, this makes
  `systemd-confext status` unable to detect the active confexts (even though they are indeed
  loaded and active).

Design/scope:

- To keep Forklift simple, I would prefer not to add functionality into Forklift for deduplicating
  large files across staged pallet bundles in Forklift's stage store. I am open to changing my mind,
  especially if other people can give me advice or help out with the initial design or
  implementation of such functionality.
- To keep Forklift reasonably simple for my primary use-case for it and to keep it flexible enough
  for maintainers of custom OS images to use in different ways according to their needs, I currently
  do not plan to have Forklift manage FS mounts itself. So the workflow to change/update the
  sysexts/confexts on the system will probably always involve either:

    1. totally replacing the local pallet from a remote source, or
    2. modifying the local pallet (and then staging the modified
       pallet, either explicitly by running `forklift plt stage` afterwards or implicitly by
       including the `--stage` flag on certain pallet-modifying subcommands of `forklift plt`),

  and then either:

    1. rebooting (if you're on a custom OS image which integrates Forklift with
       `/var/lib/extensions` and `/var/lib/confexts`, such as this repo's OS image), or
    2. running some command/script which re-mounts `/var/lib/extensions` and `/var/lib/confexts` and
       then reloads systemd's view of the sysexts/confexts (which is what this repo's
       `/usr/bin/forklift-stage-apply-systemd` script does).

  If this workflow turns out to be too unwieldy, I'm potentially interested in the following
  possibilities:

    1. providing a way to use one or more shell scripts (which can include some steps to e.g. reload
       systemd's view of sysexts/confexts) or shell commands as a hook to be automatically run by
       Forklift after any operation which stages the local pallet; or
    2. adjusting the design of what is currently implemented in Forklift so that it's a bit nicer
       for managing sysexts/confexts, but without sacrificing usability in the other workflows which
       Forklift must support; or
    3. making a separate tool which uses the same internal code as Forklift but provides a CLI
       designed specifically for managing sysexts/confexts (and perhaps provides tighter integration
       for systemd and for management of FS mounts, and/or tighter integration with
       systemd-sysext/confext's extension paths); or
    4. something else

  but these are not high priorities for me in the near future because I am not daily-driving
  sysexts/confexts yet (and because the system I'm developing Forklift for has not finished its
  migration from Raspberry Pi OS 11 to Raspberry Pi OS 12, which adds systemd-sysext support; and
  because in that project I'll be using systemd-sysexts/confexts together with Forklift's other
  features).

  If you want to fork Forklift or lift code out of it for your own independent
  experiments to make something more tailored to systemd-sysext/confext workflows, please feel free
  to do so (but please follow the requirements of the Apache-2.0 license which Forklift is released
  under)! Warning: my code is still immature enough that it will probably undergo some additional
  major refactoring iterations, so don't expect too much in terms of quality. Also, I haven't
  written thorough software tests yet - I just have a few end-to-end tests on certain parts of
  Forklift 🫠.
- Forklift is a large binary (~20 MB compressed, ~60 MB uncompressed) because it's also designed as
  a tool to manage all Docker Compose apps deployed on a system, and the fastest/easiest way for me
  to implement that was to have Forklift import github.com/docker/compose/v2 as a library. Making
  Forklift smaller is not a priority for me in the foreseeable future, but it would be nice to do
  eventually - assuming it doesn't add too much complexity.
