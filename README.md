# ublue-forklift-sysext-demo

A simple demo of using Forklift to distribute & manage sysexts in a Fedora OSTree-based system

# Introduction

This repository provides a simple command-line-only demo for integrating
[Forklift](https://github.com/PlanktoScope/forklift) with
[systemd-sysext](https://www.freedesktop.org/software/systemd/man/latest/systemd-sysext.html)
in a Fedora OSTree-based system meant to be run in a VM. To keep this demo small enough that you
don't try to rely on it for serious use, the OS image does not include a graphical desktop
environment (actually I was hoping that layering my OS image off of
[ghcr.io/ublue-os/base-main](https://github.com/ublue-os/main/pkgs/container/base-main)
would enable me to generate an installer ISO less than 2 GB so that I could upload it as an
attachment to GitHub Releases, but the
[JasonN3/build-container-installer](https://github.com/JasonN3/build-container-installer) action
makes a 2.8 GB installer anyways 🥲).

# Usage

(the guide below refers to terms specific to Forklift; you can jump down to the
[Explanation](#explanation) section to read a long summary of what those terms mean)

## Set up your VM

You will need to download the latest version of the installer ISO. To do so, go to
<https://github.com/ethanjli/ublue-forklift-sysext-demo/actions>, click on the most recent workflow
run which completed successfully, and download the `ublue-forklift-sysext-demo-latest.zip` artifact
from it (the download should be ~2.8 GB). The ZIP file contains the installer ISO file; you should
extract the ISO file, create a new VM with it, and go through the installer; make sure to create a
user for yourself.

After you finish installation, restart the VM, and log in, then you should run (without `sudo`!):

```
just-setup-forklift-staging
```

That command will enable you to run `forklift pallet switch` (or `forklift pallet stage`) commands
(described below) without having to use `sudo -E` and without having to set
`FORKLIFT_STAGE_STORE=/var/lib/forklift/stages` as an environment variable for those commands.

If you run `systemd-sysext status`, you can confirm that there are no sysexts/confexts yet on your
system.

## Use a pallet

This VM image comes without a Forklift pallet on your first boot, so that you can learn how to use a
pallet. This guide will use the pallet at the latest commit from the `main` branch of
[github.com/ethanjli/pallet-example-exports](https://github.com/ethanjli/pallet-example-exports)
and apply it to your VM in order to add a "hello world" sysext+confext to your VM, but you can make
your own pallet and use it instead.

To clone and stage the pallet, just run:

```
forklift pallet switch github.com/ethanjli/pallet-example-exports@main
```

(Note: if you hate typing, then you can replace `pallet` with `plt` - that's three entire keypresses
saved!!)

If you run `systemd-sysext status` again, you can confirm that there are still no sysexts/confexts
yet on your system. Then you should reboot (or, if you're really *really* impatient and don't want
to reboot, run `sudo forklift-stage-apply-systemd`).

You should then see new extensions if you run `systemd-sysext status`. You should also see that a
new service has just run, if you check its status with
`systemctl status hello-world-extension.service`. You should also see a script at
`/usr/bin/hello-world-extension`.

You can switch to another pallet from GitHub/GitLab/etc. using the `forklift pallet switch` command;
it will totally replace the contents of `~/.local/share/forklift/pallet` and create a new staged
pallet bundle in the stage store. Each time you run `forklift pallet switch` or
`forklift pallet stage`, forklift will create a new staged pallet bundle in the stage store (which
is at both `~/.local/share/forklift/stages` and `/var/lib/forklift/stages`). You can query and
modify the state of your stage store by running `forklift stage show` and by running other
subcommands of `forklift stage`.

## Modify a pallet and use it

There will be a nicer CLI workflow in the future for modifying pallets, but for now in order to
modify your local copy of the pallet you should directly edit files in the Git repo which is your
pallet, at `~/.local/share/forklift/pallet`. Then you can run `forklift pallet stage` (and reboot
again or run `forklift-apply-systemd`) to preview it. Warning: if you have changes which you haven't
pushed up to GitHub/etc. and then you run `forklift pallet switch {pallet-path}@{version-query}`,
your modifications to your pallet will all be deleted/overwritten and replaced with the pallet
you're switching to! If you are thinking of doing that, you should first commit and push your
changes to GitHub/GitLab/etc.

# Explanation

## What is Forklift? What is a "pallet"?

Forklift is an experimental prototype tool primarily designed to make it simpler to build custom OS
images of non-atomic Linux distros which need to provide a set of Docker Compose apps and/or a
custom layer of any OS files (where the specific directories to layer should be decided by the
maintainer of the custom OS image, not by Forklift); and to enable users/operators to quickly &
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
also use `bootc switch`. Behind-the-scenes, running
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

This script is run as part of early (or early-ish) boot every time the OS boots up. It will:

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
   recommend just rebooting instead.
7. Run `forklift stage apply` to update the deployed Docker Compose apps (only if there are any, and
   only if `/var/run/docker.sock` exists), and record in Forklift's stage store that the staged
   pallet bundle was successfully applied so that it won't be garbage-collected if you run
   `forklift stage prune-bundles` to clean up Forklift's stage store)
   (Note: I still need to implement some functionality in Forklift to handle the case that Docker
   is not installed, so for now you should just avoid running `forklift stage prune-bundles` unless
   you want to delete everything in your stage store).


# Caveats/Limitations

- This demo disables SELinux policy enforcement because of
  <https://github.com/systemd/systemd/issues/23971>, and because I don't have enough experience with
  SELinux to change the SELinux policy so that the overlays don't cause everything (e.g. sudo and
  chkpwd) to break after systemd-sysext enables filesystem overlays (or maybe it's the bind mounts
  I make in this demo for Forklift?), and because this is just a demo. If someone can fix
  the SELinux policies for this demo, please submit a pull request at
  <https://github.com/ethanjli/ublue-forklift-sysext-demo/pulls>!
- Currently Forklift can only handle plain-directory sysext images. I am anyways planning to add
  functionality to Forklift to download external/online files into the export directory (and it will
  probably be heavily inspired by
  [how chezmoi does a similar task](https://www.chezmoi.io/user-guide/include-files-from-elsewhere/)),
  and then Forklift should be able to handle other sysext image formats. Once I do that, I'd like to
  add a demo of adding a Docker sysext (and system services) into this demo.
- To keep Forklift simple, I do not plan to add functionality into Forklift to deduplicate large
  files across staged pallet bundles in Forklift's stage store (though I would be interested in
  supporting use of OCI images rather than Git repos to distribute Forklift repos & pallets as well
  as external/online files to be assembled into the export directory, in which case deduplication of
  large sysext images could be feasible).
- To keep Forklift simple for my primary use-case for it and to keep it flexible enough for
  maintainers of custom OS images to use according to their needs, I currently do not plan to have
  Forklift manage FS mounts itself. So the workflow to change the sysexts on the system will
  (probably) always involve modifying the local pallet (and then running `forklift pallet stage`)
  or totally replacing the local pallet from a remote source, and then either:

    1. rebooting (on a custom OS image which integrates Forklift with `/var/lib/extensions` and
       `/var/lib/confexts`, such as this repo's OS image); or
    2. running some command/script which re-mounts `/var/lib/extensions` and `/var/lib/confexts` and
       then reloads systemd's view of the sysexts/confexts (such as this repo's
       `/usr/bin/forklift-stage-apply-systemd` script).

  I'm potentially interested in the following possibilities:

    1. making a separate tool which uses the same internal code as Forklift but provides a CLI
       designed specifically for managing sysexts/confexts (and perhaps provides tighter integration
       for systemd and management of FS mounts or with systemd-sysext's extension paths); or
    2. adjusting the design of what is currently implemented in Forklift so that it's a bit nicer
       for managing sysexts/confexts, but without sacrificing usability in the other workflows I need
       Forklift to support;

  but these are not high priorities for me in the near future because I am not daily-driving
  sysexts/confexts yet (and because the system I'm developing Forklift for has not finished its
  migration from Raspberry Pi OS 11 to Raspberry Pi OS 12, which adds systemd-sysext support). If
  you want to fork Forklift or lift code out of it for your own independent experiments to make
  something more tailored to systemd-sysext workflows, please feel free to do so (but please follow
  the requirements of the Apache-2.0 license which Forklift is released under)! Warning: my code is
  still immature enough that it will probably undergo some additional major refactorings, so don't
  expect too much in terms of quality. Also, I haven't written any software tests yet 🫠.
- The CLI for modifying pallets (e.g. adding package deployments) is only partially implemented; for
  anything besides adding/updating repo requirements (currently `forklift dev pallet add-repo`,
  though I plan to add `forklift pallet require-repo` as a nicer alias), I just use a file browser
  to manually create the necessary files. This means Forklift currently doesn't have a CLI
  command roughly analogous to `systemctl enable {unit}` or `apk add {package}`. I plan to
  eventually add a more complete CLI for editing pallets.
- Forklift is a large binary (~20 MB compressed, ~60 MB uncompressed) because it's also designed as
  a tool to manage all Docker Compose apps deployed on a system, and the fastest/easiest way to
  implement that was by including github.com/docker/compose/v2 as a library which I use. Making
  Forklift smaller is not a priority for me in the foreseeable future, but it would be nice to do
  eventually if it doesn't add too much complexity.
