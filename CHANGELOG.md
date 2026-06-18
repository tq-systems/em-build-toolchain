## [2.0.7] - 2026-06-18
### Added
- common image now exports PUBLIC_TOOLCHAIN_DOCKER_TAG as an ENV variable so the image version is
  readable from inside a running container; amd64 and aarch64 inherit this via their common base

## [2.0.6] - 2026-06-12
### Fixed
- Prevent overriding the VERSION.txt file during emit-build

## [2.0.5] - 2026-06-11
### Changed
- ci: bump base CI ref to v3.1.2
- pin em-build to v9.0.3 so the aarch64 bootloader and SDK come from a fixed release instead of master snapshots

## [2.0.4] - 2026-06-08
### Added
- Add .SECONDEXPANSION to enable overwriting prerequisites

### Changed
- Simplified deployment behavior (again)
- Ensure that snapshots are deployed to a subdirectory derived from the branch
- apps/public/Makefile: archive target resolves git submodules into the working tree and re-enables
  --exclude-vcs so snapshot archives contain dependencies but no VCS metadata
- The target prerequisites have been improved based on the dependency trees

### Removed
- recursive Make commands
- Some make targets for intermediate steps were removed:
  backend-debug, backend-release, frontend-release, bundle-build, empkg-pack

## [2.0.3] - 2026-05-22
### Changed
- Ensure that snapshots are deployed to a subdirectory derived from the branch

## [2.0.2] - 2026-05-20
### Changed
- ci: Update base ci reference to v3.1.0
- amd64: Update Go from 1.25.10 to 1.26.3
- common: Add pyyaml to the venv

### Fixed
- base-latest: Update app versions

## [2.0.1] - 2026-05-15
### Changed
- ci: update base CI reference to v3.0.2
- Go: update to 1.25.10
- Node: update to 22.13.1
- libdeviceinfo: update to 1.9.0

## [2.0.0] - 2026-05-06
### Changed
- ci: update base CI reference to v3.0.0 (Ubuntu 24.04)
- amd64.Dockerfile: replace libcurl3-dev with libcurl4-openssl-dev for Ubuntu 24 compatibility
- amd64.Dockerfile: add libsoup-3.0-dev and libgupnp-1.6-dev to regular package install, remove Ubuntu 24 workaround
- docker: install Python tools (including python-gitlab) in venv with pinned versions for Ubuntu 24.04
- common.Dockerfile: install python3-venv for venv support

### Removed
- amd64.Dockerfile: remove temporary Ubuntu 24.04 noble apt-sources workaround

## [1.2.0] - 2026-04-23
### Added
- Add makefiles and ci/packages.yml entry point for building and publishing npm packages

### Changed
- Update golangci-lint to 2.11.4
- Introduce a default config for "go-lint" and "go-sec" Make targets, it can be overridden by a
  .golangci.yml file in the backend directory of the app repo or any directory up to root
- Simplify base inclusion

## [1.0.1] - 2026-04-10
### Changed
- Update core to v9.0.1

### Fixed
- apps/public/Makefile: Remove --exclude-vcs from archive target so .git is included in app
  archives, enabling git submodule update in bundle integration tests
- apps/public/Makefile: Move package.mk inclusion to prevent service files for apps without backend

## [v1.1.2] - 2026-04-02
### Changed
- base: update ci ref to v2.1.1
- base: downgrade docker tag to v2.1.1

## [v1.1.1] - 2026-04-02
### Fixed
- apps/public/Makefile: Remove --exclude-vcs from archive target so .git is included in app
  archives, enabling git submodule update in bundle integration tests

## [1.1.0] - 2026-04-01
### Changed
- Updated base reference and improved gitlab ci workflows

## [v1.0.0] - 2026-03-24
### Added
- Option to use internal toolchain extensions
- sbom feature for applications
- Add em-install-devel-cert.sh script
- Add link to latest empkg

### Changed
- ci: MR pipelines use isolated Docker image tag mr-${CI_MERGE_REQUEST_IID} to prevent cross-MR image overwrites
- Install python-gitlab in common base image
- Update Go to 1.25.5
- Update libdeviceinfo to 1.8.0
- Remove irrelevant variant handling of applications
- Apps are stored in the deploy folder instead of the artifacts folder
- Replace corepack-based yarn installation with direct binary download to ensure fixed yarn version regardless of project configuration
- ci: Remove obsolete artifacts handling
- Use 'main' as subfolder for 'master' deployments

### Fixed
- apps/public/Makefile: include frontend/test/ in snapshot archives by removing --exclude=test from archive target
- go-generate-code: fail if untracked files are present
- backend-go-mod.mk: ignore mocks for code coverage calculation
- Critial rauc update issue with the keyring
- Copy docker/usr/local in common docker image
- TQEM_GIT_REFERENCE: use symbolic-ref for branch determination
- frontend-yarn.mk: yarn-upgrade target
- package.mk: Prevent self-referential symlink when PKG_FILE equals PKG_LINK

### Removed
- frontend-yarn.mk: broken yarn-outdated target

## [v0.1.0] - 2025-08-18
### Added
- First toolchain release

