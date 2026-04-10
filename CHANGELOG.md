## [1.0.1] - 2026-04-10
### Changed
- Update core to v9.0.1

### Fixed
- apps/public/Makefile: Remove --exclude-vcs from archive target so .git is included in app
  archives, enabling git submodule update in bundle integration tests
- apps/public/Makefile: Move package.mk inclusion to prevent service files for apps without backend

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

