# toolchain
## Description
This project produces docker images that are used to build and test
Energy Manager artifacts. These are mainly apps and bundles, but can also be
tools, libraries or signed third-party software.

## License information
This project is licensed under the TQSPSLA-1.0.3 license, see LICENSE file for further details.

    SPDX-License-Identifier: LicenseRef-TQSPSLA-1.0.3

All files in this project are classified as product-specific software and bound
to the use with the TQ-Systems GmbH product: EM400

## Development
### Pull images
Pull all images from registry:
```bash
$ make pull
```

### Build images
Build all images:
```bash
$ make all
```
Build a specific image:
```bash
$ make common
$ make amd64
$ make armel
$ ...
```
By default the current snapshots of the core images and the cross-compiler
toolchains are used and `BUILD_TAG` is set to `latest`.

Additionally, the variable `BUILD_ARGS` may be set to supply additional
arguments to the build process. The following command builds the images
from scratch:
```bash
$ make all BUILD_ARGS=--no-cache
```

### Release images and push them in the docker registry
In order to be able to test images in the CI without endangering ongoing
operations, images must be built with other docker tags and pushed to the
docker registry. The tags usually have the name of a ticket or a test prefix,
e.g. `test-feature`.

Release test images:
```bash
$ make test-release BUILD_TAG=test-feature
```

### Deploy images
Push images into the docker registry:
```bash
$ make push
```

### Build and deploy
The following command is used to build and push the latest images or releases.
Be careful with it, as it can override already pushed images in the docker
registry.
```bash
$ make release
```

### Clean up
Clean up the project directory and remove unused data from system:
```bash
$ make clean
```

### Run shell inside a container
```bash
docker run -it --rm <registry>/<image>:<tag> /bin/bash
```

## Release
### Build
A release build is triggered by pushing a tag.

The requirement for a successful build is that the artifacts to be installed
are already built and accessible in the desired version.

### Git
The git tags of this project feature semantic versioning for this project.
Their pattern is `vX.Y.Z` in which X is the major version, Y is the minor
version number and Z is the patch level.

The release branches use this pattern but with variable patch level releases,
for example `release/v1.2.x`.
