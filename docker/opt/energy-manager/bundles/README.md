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

    BUNDLE = my-bundle-development
    RELEASE ?= my-bundle

    VERSION = 1.0.0-pre-$$(date -u "+%Y%m%d%H%M%S")

    include /opt/energy-manager/bundles/Makefile

If the VERSION is removed, git information will be used for creating it.
See `common/README.md` for further information.

## Build command

    make prepare && MACHINES=<MACHINE> make all

# Files
## Makefile
This is the entrypoint of a Makefile in a bundle project, it includes more Makefiles provided
by the toolchain and described below.

The following keys have a default value, but they are typically overridden from the bundle project:

| Key         | Default value                   | Description                |
|-------------|---------------------------------|----------------------------|
| BUNDLE      | (Derived for project directory) | Name of development bundle |
| RELEASE     | (Derived for project directory) | Name of release bundle     |
| VERSION     | (Derived from git)              | Bundle version             |

## build.mk
This Makefile provides the bundle build. The MACHINES variable is needed for the build target.
The variable EMIT_BUNDLE_COMPRESSION enables "Bundle compression".
If enabled the built-in apps are compressed to a mountable squashfs image
inside the root file system. The root file system as a whole is then compressed as well.

By default, EMIT_BUNDLE_COMPRESSION is not defined.
The compression then depends on the MACHINE:

| EMIT_BUNDLE_COMPRESSION  | MACHINE    | Bundle compression |
|--------------------------|------------|--------------------|
| Not defined (default)    | em-aarch64 | enabled            |
| Not defined (default)    | em310      | disabled           |

If EMIT_BUNDLE_COMPRESSION is set, it overrides the default behavior:

| EMIT_BUNDLE_COMPRESSION  | MACHINE    | Bundle compression |
|--------------------------|------------|--------------------|
| 'true'                   | em-aarch64 | enabled            |
| 'true'                   | em310      | enabled            |
| 'false'                  | em-aarch64 | disabled           |
| 'false'                  | em310      | disabled           |

### Disable Firewall
By setting the TQEM_BUNDLE_DISABLE_FIREWALL variable to 'true', the em-firewall service can be disabled.
