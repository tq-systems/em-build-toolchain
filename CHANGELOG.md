## [2.0.0] - 2026-05-06
### Added
- Add makefiles and ci/packages.yml entry point for building and publishing npm packages

### Changed
- ci: update base CI reference to v3.0.0 (Ubuntu 24.04)
- Update golangci-lint to 2.11.4
- Introduce a default config for "go-lint" and "go-sec" Make targets, it can be overridden by a
  .golangci.yml file in the backend directory of the app repo or any directory up to root
- Simplify base inclusion
- amd64.Dockerfile: replace libcurl3-dev with libcurl4-openssl-dev for Ubuntu 24 compatibility
- amd64.Dockerfile: add libsoup-3.0-dev and libgupnp-1.6-dev to regular package install, remove Ubuntu 24 workaround
- docker: install Python tools (including python-gitlab) in venv with pinned versions for Ubuntu 24.04
- common.Dockerfile: install python3-venv for venv support

### Removed
- amd64.Dockerfile: remove temporary Ubuntu 24.04 noble apt-sources workaround

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

