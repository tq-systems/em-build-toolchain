export TQEM_ARTIFACTS_DIRNAME ?= artifacts
export TQEM_DEPLOY_DIRNAME    ?= deploy
export TQEM_DOWNLOADS_DIRNAME ?= downloads
export TQEM_TMP_DIRNAME       ?= tmp

# Subfolders inside the deploy tree. Every artifact is placed into one of these while building, so
# the deploy target only has to mirror the tree (no path building in CI).
export TQEM_BIN_DIRNAME ?= bin
export TQEM_DOC_DIRNAME ?= doc
export TQEM_QA_DIRNAME  ?= qa
export TQEM_SRC_DIRNAME ?= src

export TQEM_SNAPSHOTS_DIRNAME  ?= snapshots
export TQEM_RCS_DIRNAME        ?= release-candidates
export TQEM_RELEASES_DIRNAME   ?= releases
export TQEM_BUILD_TYPE_DIRNAME ?= ${TQEM_SNAPSHOTS_DIRNAME}

# Paths
export TQEM_PROJECT_ROOT_PATH = ${CURDIR}
export TQEM_ARTIFACTS_PATH    = ${TQEM_PROJECT_ROOT_PATH}/${TQEM_ARTIFACTS_DIRNAME}
export TQEM_DEPLOY_PATH       = ${TQEM_PROJECT_ROOT_PATH}/${TQEM_DEPLOY_DIRNAME}
export TQEM_DOWNLOADS_PATH    = ${TQEM_PROJECT_ROOT_PATH}/${TQEM_DOWNLOADS_DIRNAME}
export TQEM_TMP_PATH          = ${TQEM_PROJECT_ROOT_PATH}/${TQEM_TMP_DIRNAME}

# Local deploy subfolders that producers write into (mirrored 1:1 to the destination).
export TQEM_DEPLOY_BIN_PATH   = ${TQEM_DEPLOY_PATH}/${TQEM_BIN_DIRNAME}
export TQEM_DEPLOY_DOC_PATH   = ${TQEM_DEPLOY_PATH}/${TQEM_DOC_DIRNAME}
export TQEM_DEPLOY_QA_PATH    = ${TQEM_DEPLOY_PATH}/${TQEM_QA_DIRNAME}
export TQEM_DEPLOY_SRC_PATH   = ${TQEM_DEPLOY_PATH}/${TQEM_SRC_DIRNAME}

export TQEM_BASE_DEPLOY_PATH    ?= $(HOME)/workspace/tqem/deploy
export TQEM_APPS_DEPLOY_PATH    ?= ${TQEM_BASE_DEPLOY_PATH}/${TQEM_BUILD_TYPE_DIRNAME}/apps
export TQEM_BUNDLES_DEPLOY_PATH ?= ${TQEM_BASE_DEPLOY_PATH}/${TQEM_BUILD_TYPE_DIRNAME}/bundles
export TQEM_APPS_CACHE_PATH     ?= $(HOME)/workspace/tqem/cache/apps

# Variables
# Set to true by the CI, false for local builds. Apps never set this themselves.
export TQEM_CI            ?= false
# Set iff HEAD is an exact tag; used to distinguish release from snapshot builds.
export TQEM_GIT_TAG       ?= $(shell git describe --exact-match --tags HEAD 2>/dev/null)
# A snapshot pipeline overwrites its target folder in place, so its artifacts need a stable
# filename instead of a version-bearing one. Derived from the two variables above; the value of
# TQEM_CI is read, so setting it to false really means a local build.
export TQEM_SNAPSHOT_BUILD ?= $(if ${TQEM_GIT_TAG},,$(filter true,${TQEM_CI}))
export TQEM_GIT_REFERENCE ?= $(shell git describe --exact-match --tags HEAD 2>/dev/null \
	|| git symbolic-ref --short HEAD 2>/dev/null || git rev-parse --short=8 HEAD)
export TQEM_PROJECT_URL   ?= $(shell git remote get-url origin)
export TQEM_PROJECT_NAME  ?= $(shell basename "${TQEM_PROJECT_URL}" .git)
