# Introduction
Here are the Makefiles for the bundle projects. First, the minimum requirements for a Makefile
from a bundle project are shown, then the individual files are described in more detail.

# Bundle project
## Mandatories
From make's point of view, only the include command is required to be able to build a bundle
from a bundle project:

    include /opt/energy-manager/bundles/Makefile

## Example

Example of a simple bundle Makefile:

    BUNDLE_NAME = my-bundle

    include /opt/energy-manager/bundles/Makefile

If the VERSION is removed, git information will be used for creating it.
See `common/public/README.md` for further information.

## Build command

    make prepare && make all

# Files
## Makefile
This is the entrypoint of a Makefile in a bundle project, it includes more Makefiles provided
by the toolchain and described below.

The following keys have a default value, but they are typically overridden from the bundle project:

| Key                 | Default value                    | Description                |
|---------------------|----------------------------------|----------------------------|
| DEVEL_BUNDLE_NAME   | (Derived from project directory) | Name of development bundle |
| RELEASE_BUNDLE_NAME | (Derived from project directory) | Name of release bundle     |
| VERSION             | (Derived from git)               | Bundle version             |

## build.mk
This Makefile provides the bundle build. The variable EMIT_BUNDLE_COMPRESSION enables the bundle
compression feature. If enabled the built-in apps are compressed to a mountable squashfs image
inside the root file system. The root file system as a whole is then compressed as well.

### Disable Firewall
By setting the TQEM_BUNDLE_DISABLE_FIREWALL variable to 'true', the em-firewall service can be disabled.
