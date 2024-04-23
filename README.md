# ublue-forklift-sysext-demo

A simple demo of using Forklift to distribute & manage sysexts in a Fedora OSTree-based system

# Introduction

This repository provides a simple command-line-only demo for integrating
[Forklift](https://github.com/PlanktoScope/forklift) with
[systemd-sysext](https://www.freedesktop.org/software/systemd/man/latest/systemd-sysext.html)
in a Fedora OSTree-based system meant to be run in a VM. To keep this demo small enough that I can
upload ISO images on GitHub Releases, the OS image does not include a desktop environment.

## What is Forklift?

Forklift is an experimental prototype tool primarily designed for the purpose of making it simpler
to build custom OS images of non-atomic Linux distros which need to provide a set of Docker
Compose apps and/or a custom layer of any OS files (where the specific directories to layer should
be decided by the maintainer of the custom OS image, not by Forklift); and to quickly & cleanly
upgrade/downgrade/reprovision their deployment of those Docker Compose apps and OS files without
having to re-install the custom OS image. Currently Forklift is designed/developed/tested mainly for
the Raspberry Pi OS-based
[operating system of a specific hardware project](https://docs-edge.planktoscope.community/reference/software/architecture/os/)
which is currently still tied to an older version of Raspberry Pi OS (bullseye) with a pre-sysext
version of systemd. But since sysext images are also just OS files, we can repurpose Forklift to
deploy a particular set of sysext images (according to a configuration specified for Forklift) onto
the OS.

In Forklift, OS files (and Docker Compose apps, but we don't care about them here) are modularized
into *packages*; a package is just a directory which contains a special `forklift-package.yml` file
and which is somewhere inside a *repository*, which is just a Git repository with a special
`forklift-repository.yml` file at the root of the repository. A package can declare some files
within the package's directory which should be made available at some declared paths in a special
*export directory* (more on this later). Forklift packages and repositories are roughly
analogous to [Go packages and modules](https://go.dev/ref/mod), respectively - except that Forklift
packages/repositories cannot "import" or "include" other Forklift packages/repositories, and the
path of the Forklift repository must be exactly the path of its Git repository (e.g.
`github.com/ethanjli/example-exports` is valid, but `github.com/ethanjli/example-exports/v2`
and `github.com/ethanjli/forklift-demos/example-exports` are invalid); these differences from the
design of Go Modules keep Forklift's design simpler for Forklift's specific use-case.

Forklift packages cannot be deployed/installed on their own. Instead, we create a Forklift *pallet*
to declare the complete configuration of all Forklift packages which should be deployed on a
computer. A pallet is just a Git repository with a special `forklift-pallet.yml` file at the root
of the repository, and some other special files in a special directory structure. We can then use
Forklift or Git to clone the pallet to our computer, and then we can use Forklift to *stage* the
pallet to be applied to our computer. When Forklift stages a pallet, it copies various files into
a new directory called a *staged pallet bundle* (look,, naming is hard) in a special directory
called the *stage store* (look,,, naming is hard!!). Inside the staged pallet bundle is a subdirectory
called `exports` which contains all the files declared for export by the pallet's deployed packages.

We can add a systemd service which runs during early boot (e.g. before `sysinit.target`) and queries
Forklift for the path of the staged pallet bundle which should be applied to the computer, and then
bind-mounts or overlay-mounts or symlinks-to a subdirectory in that bundle's `exports` directory
for an arbitrary path on the filesystem, e.g. `/usr` or `/etc` or `/var/lib/extensions`. Then we can
add a systemd service which refreshes systemd's view of systemd units/sysexts/confexts/etc. The demo
in this repository sets up a read-only bind-mount between
`/var/lib/forklift/stages/{id of the staged pallet bundle to apply}/exports/sysexts` and
`/var/lib/extensions`.

# Usage

## Setup

### Prepare your VM

After starting the VM and logging in, you should run:

```
sudo systemctl enable bind-.local-share-forklift-stages@home-$USER.service
```

This will enable you to run `forklift pallet switch` (or `forklift pallet stage) commands
(described below) without using `sudo -E` and without having to specify
`FORKLIFT_STAGE_STORE=var/lib/forklift/stages` as an environment variable for
`forklift pallet switch` (or `forklift pallet stage`) commands.

### Use a pallet

This VM image comes without a pallet on your first boot, so that you can learn how to use a pallet.
This guide will apply the latest commit from the `main` branch of
[github.com/ethanjli/pallet-example-exports](https://github.com/ethanjli/pallet-example-exports)
to your VM, but you can make your own pallet and use it instead.

To clone and stage the pallet, just run (note: if, like me you hate typing, then you can replace
`pallet` with `plt` - that's three entire keypresses saved!):

```
forklift pallet switch github.com/ethanjli/pallet-example-exports@main
```

This command is intended to feel roughly familiar/intuitive to people who use `bootc switch`.
Behind-the-scenes, it will:

1. Clone the pallet as a Git repository to a local copy at `~/.local/share/forklift/pallet`, and
   check out the latest commit of the `main` branch. This step can also be run on its own with
   `forklift pallet clone github.com/ethanjli/pallet-example-exports@main`.
2. Download any external Forklift repositories required by the pallet into
   `~/.cache/forklift/repositories`; our pallet doesn't require any external repositories, and
   instead deploys packages defined within itself (since our pallet is also a Forklift repository).
   This step can also be run on its own with `forklift pallet cache-repo`.
3. Run some checks to ensure that the pallet is valid, e.g. that deployed packages don't conflict
   with each other. Our pallet doesn't have any conflicting package deployments, because it doesn't
   deploy multiple packages which all try to export files at the same target paths.
   This step can also be run on its own with `forklift pallet check`.
4. Stage the pallet to be used on the next reboot, by creating a new staged pallet bundle in
   `~/.local/share/forklift/stages` (which, in this OS image, is attached to
   `/var/lib/forklift/stages` via a bind-mount).
   This step can also be run on its own with `forklift pallet stage`.

Then you should reboot (or, if you're really *really* impatient and don't want to reboot) run the
`forklift-stage-apply-systemd` script with `sudo`, which will:

1. Query Forklift to determine the path of the next staged pallet bundle to be applied. This path
   will be a subdirectory of `/var/lib/forklift/stages`.
2. Mount (or re-mount) that staged pallet bundle's `exports/sysexts` subdirectory to
   `/var/lib/extensions`.
3. Mount (or re-mount) that staged pallet bundle's `exports/confexts` subdirectory to
   `/var/lib/confexts`.
4. Run `systemd-sysext refresh`.
5. Run `systemctl daemon-reload`.
6. Run `systemctl restart --no-block sockets.target timers.target multi-user.target default.target`.
   Warning: if you run `forklift-stage-apply-systemd` after boot, this will not attempt to stop any
   systemd units associated with sysexts/confexts which you've removed after boot. This is why I
   recommend just rebooting instead.
7. Run `forklift stage apply` to update the deployed Docker Compose apps (if there are any), and
   record in Forklift's stage store that the staged pallet bundle was successfully applied (so that
   it won't be garbage-collected if you run `forklift stage prune-bundles` to clean up Forklift's
   stage store).

You should then see new extensions if you run `systemd-sysext status`. On your next reboot, you'll
see that a new service has run as part of boot if you run
`systemctl status hello-world.service`.

You can also subsequently switch to another pallet from GitHub/GitLab/etc. using the
`forklift pallet switch` command. Each time you run `forklift pallet switch` or
`forklift pallet stage`, forklift will create a new staged pallet bundle in the stage store. You can
query and modify the state of your stage store with `forklift stage show` and with other subcommands
of `forklift stage`.

### Modify a pallet and use it

There will be a nicer CLI workflow in the future for modifying pallets, but for now in order to
modify your local copy of the pallet you should directly edit files in the Git repo which is your
pallet. Then you can run `forklift pallet stage` (and reboot again or run `forklift-apply-systemd`)
to preview it. Warning: if you have changes which you haven't pushed up to GitHub/etc. and then
you run `forklift pallet switch {pallet-path}@{version-query}`, your modifications to your pallet
will all be deleted/overwritten and replaced with the pallet you're switching to!

# Caveats/Limitations

- Currently Forklift can only handle plain-directory sysext images. I am anyways planning to add
  functionality to Forklift to download external/online files into the export directory (and it will
  probably be heavily inspired by
  [how chezmoi does a similar task](https://www.chezmoi.io/user-guide/include-files-from-elsewhere/)),
  and then Forklift should be able to handle other sysext image formats.
- To keep Forklift simple, I do not plan to add functionality into Forklift to deduplicate large
  files across staged pallet bundles in Forklift's stage store (though I would be interested in
  supporting use of OCI images rather than Git repos to distribute Forklift repos & pallets as well
  as external/online, in which case deduplication of large sysext images could be feasible).
- Forklift is a large binary (~20 MB compressed, ~60 MB uncompressed) because it's also designed as
  a tool to manage all Docker Compose apps deployed on a system, and the fastest/easiest way to
  implement that was by including github.com/docker/compose/v2 as libraries which I use. Making
  Forklift smaller is not a priority for me in the foreseeable future, but it would be nice to do
  eventually if it doesn't add too much complexity.
- To keep Forklift simple for my primary use-case for it and flexible for maintainers of custom OS
  images to use according to their needs, I currently do not plan to have Forklift manage FS mounts
  itself. So the workflow to change the sysexts on the system will always involve either:

    1. Modifying the local pallet, then running `forklift pallet stage`, and then rebooting (on a
       custom OS image which integrates Forklift with `/var/lib/extensions`), or
    2. Modifying the local pallet, then running `forklift pallet stage`, and then running some other
       command/script which re-mounts `/var/lib/extensions` and then reloads systemd's view of the
       sysexts.

  I'm interested in the following possibilities:

    1. making a separate tool using the same internal code as Forklift which provides a CLI
       specifically for managing sysexts (and perhaps tighter integration for systemd and management
       of FS mounts); or
    2. adjusting the design of what is currently implemented in Forklift so that it's a bit nicer
       for managing sysexts, but without sacrificing usability in the other workflows I need
       Forklift to support;

  but these are not high priorities for me in the near future because I am not daily-driving sysexts
  yet (and because the system I'm developing Forklift for has not finished its migratiion from
  Raspberry Pi OS 12 to Raspberry Pi OS 13, which adds systemd-sysext support). If you want to
  lift code out of Forklift for your own independent experiments to make something more tailored to
  systemd-sysext, please feel free to do so (but follow the requirements of the Apache-2.0 license
  which Forklift is released under)!
- The CLI for modifying pallets (e.g. adding package deployments) is only partially implemented; for
  anything besides adding/updating repo requirements (`forklift pallet require-repo`), I just use a
  file browser to manually create the necessary files. This means Forklift doesn't yet have a CLI
  equivalent of `systemctl enable (unit)`. I plan to eventually add some sort of CLI for that
  workflow.
