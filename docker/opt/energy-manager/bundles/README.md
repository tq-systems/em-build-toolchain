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

## sbom.mk
The sbom target merges the app SBOMs of each bundle below deploy/bin with the core image SBOM into
one CycloneDX file per bundle, with the layers bundle, apps and operating system. It creates no
SBOM itself and runs after the build target.

An app deploys its SBOM below doc/ instead of shipping it inside the package, so the build target
copies the SBOMs of the apps of the bundle specs into artifacts/app-sboms. Their doc folder comes
from the package URL of the specs, read below TQEM_BASE_DEPLOY_PATH, so the copy follows wherever
the bundle takes its apps from. Each bundle names the apps it installs, so one directory serves
several bundles. An app whose SBOM is missing is listed in the output and in the property
emos.apps_without_sbom.

Like the app packages the folder is a directory target: it is filled once and a further build
reuses it. Delete it to collect the SBOMs again.

    make build sbom

| Key                       | Default value                                    | Description                         |
|---------------------------|--------------------------------------------------|-------------------------------------|
| TQEM_CORE_IMAGE_SBOM_FILE | SBOM next to the core image in the aarch64 image | Core image SBOM to merge            |
| TQEM_APP_SBOM_PATH        | artifacts/app-sboms                              | Folder of the collected app SBOMs   |
| TQEM_SBOM_PURL_EXCLUDES   | (empty)                                          | Leave out components whose purl contains one of these texts |
| TQEM_SBOM_OUTPUT_PATH     | deploy/doc                                       | Folder of the merged SBOM files     |

To merge with a locally built core image, point TQEM_CORE_IMAGE_SBOM_FILE to its
em-image-core-<machine>.sbom-cyclonedx_merged.json.

The package server packages.tq-group.com carries the packages without a doc folder. An app a
bundle takes from there has no SBOM to merge and is listed under emos.apps_without_sbom. The
merged SBOM of such a bundle covers the operating system and the apps from the deploy tree.
