# Images

This directory holds the Dockerfiles of the public toolchain. The internal toolchain
extends these images, see the internal toolchain project for its own images.

This file is the list of the images of this project.

| Image | Based on | Purpose |
|---|---|---|
| `common` | Ubuntu base image | Basis of all other images |
| `amd64` | `common` | Native build toolchain for amd64 |
| `aarch64` | `common`, `amd64` | Cross-build toolchain for aarch64 |

The `/opt/energy-manager` Makefiles for apps, bundles and packages (subdirectories `public`)
are part of the images and are extended by the internal toolchain.

Hand-installed tools carry no package metadata. Their versions are exposed as image labels
(`tqem.tool.*`) and can be read back from the built image.

Keep the images small. Install only what the image needs and clean the apt lists in the same
layer.

The contents (packages, tools, versions) are not listed here, see the Dockerfile of the image.
