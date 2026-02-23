export TQEM_ARTIFACTS_DIRNAME ?= artifacts
export TQEM_DEPLOY_DIRNAME    ?= deploy
export TQEM_DOWNLOADS_DIRNAME ?= downloads
export TQEM_TMP_DIRNAME       ?= tmp

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

export TQEM_BASE_DEPLOY_PATH    ?= $(HOME)/workspace/tqem/deploy
export TQEM_APPS_DEPLOY_PATH    ?= ${TQEM_BASE_DEPLOY_PATH}/${TQEM_BUILD_TYPE_DIRNAME}/apps
export TQEM_BUNDLES_DEPLOY_PATH ?= ${TQEM_BASE_DEPLOY_PATH}/${TQEM_BUILD_TYPE_DIRNAME}/bundles
export TQEM_APPS_CACHE_PATH     ?= $(HOME)/workspace/tqem/cache/apps

# Variables
export TQEM_GIT_REFERENCE ?= $(shell git describe --exact-match --tags HEAD 2>/dev/null \
	|| git symbolic-ref --short HEAD 2>/dev/null || git rev-parse --short HEAD)
export TQEM_PROJECT_URL   ?= $(shell git remote get-url origin)
export TQEM_PROJECT_NAME  ?= $(shell basename "${TQEM_PROJECT_URL}" .git)
