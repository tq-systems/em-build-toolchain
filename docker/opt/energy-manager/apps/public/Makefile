include /opt/energy-manager/common/public/environment.mk
include /opt/energy-manager/common/public/artifacts.mk
include /opt/energy-manager/common/public/version.mk
include /opt/energy-manager/common/public/deploy.mk

export APP_ID  ?= ${TQEM_PROJECT_NAME}
APP_NAME       ?= em-app-${APP_ID}

TQEM_DEPLOY_SOURCE_PATH ?= ${TQEM_DEPLOY_PATH}
TQEM_DEPLOY_DESTINATION_PATH ?= ${TQEM_APPS_DEPLOY_PATH}/${APP_ID}/${TQEM_DEPLOYMENT_SUBDIR}

DIR_APP_ROOT = /apps/installed/${APP_ID}
DIR_PACKAGE  = ${TQEM_ARTIFACTS_PATH}/package

ifndef APP_PRETTY_NAME
$(warning "APP_PRETTY_NAME is not defined.")
endif

ifndef DESCRIPTION
$(warning "DESCRIPTION is not defined.")
endif

# Building app variants is not supported by this toolchain, but it is supported by extensions
# which require certain variables as entrypoints for this purpose.
DEFAULT_VARIANT ?= default
BUILD_VARIANT   ?= ${DEFAULT_VARIANT}
FEATURE_VARIANT ?= ${DEFAULT_VARIANT}
LANG_VARIANT    ?= ${DEFAULT_VARIANT}

DIR_BACKEND_REL  ?= backend
DIR_FRONTEND_REL ?= frontend
DIR_PROFILE_REL  ?= profile
DIR_BACKEND      ?= ${TQEM_PROJECT_ROOT_PATH}/${DIR_BACKEND_REL}
DIR_FRONTEND     ?= ${TQEM_PROJECT_ROOT_PATH}/${DIR_FRONTEND_REL}
DIR_PROFILE      ?= ${TQEM_PROJECT_ROOT_PATH}/${DIR_PROFILE_REL}

# Default build flags
FRONTEND_BUILD ?= yarn
BACKEND_BUILD  ?= go-mod

BACKEND_DEBUG_BUILD ?= false

SERVICE_BUILD  ?= $(if $(BACKEND_BUILD),1,0)

PKG_ARCH ?= aarch64

BUILD_ARCHIVE = ${APP_ID}_${VERSION}.tar.gz

# First target = default target
all: empkg

# The debug build needs an additional build flag
all-debug: BACKEND_DEBUG_BUILD = true
all-debug: empkg

# Set empty targets here and override them in the included files,
# this avoids errors when an app without frontend or backend is built.
backend-prepare:
backend-deps-fetch:
backend-deps-extract:
backend-build:
backend-empkg-artifacts: backend-build
backend-finish: backend-empkg-artifacts
backend-clean:
backend-upgrade:

frontend-prepare:
frontend-deps-fetch:
frontend-deps-extract:
frontend-build:
frontend-empkg-artifacts: frontend-build
frontend-finish: frontend-empkg-artifacts
frontend-clean:
frontend-upgrade:

.PHONY: all all-debug \
	backend-prepare backend-deps-fetch backend-deps-extract backend-build \
	backend-empkg-artifacts backend-finish backend-clean backend-upgrade \
	frontend-prepare frontend-deps-fetch frontend-deps-extract frontend-build \
	frontend-empkg-artifacts frontend-finish frontend-clean frontend-upgrade

# Further targets and its prerequisites are defined here. It is strongly recommended that you avoid
# recursive make commands, as they make the process more complex and prone to errors.
prepare: version backend-deps-fetch frontend-deps-fetch

backend: backend-finish
frontend: frontend-finish
empkg: backend frontend

# Enable secondary expansion to allow the replacement of prerequisite variables.
# These variables are defined with $$(VAR) instead of $(VAR).
.SECONDEXPANSION:

ifeq ($(FRONTEND_BUILD),yarn)
  include /opt/energy-manager/apps/public/frontend-yarn.mk
endif
ifeq ($(BACKEND_BUILD),go-mod)
  include /opt/energy-manager/apps/public/backend-go-mod.mk
endif

# This needs to be included after setting build and service variables
include /opt/energy-manager/apps/public/package.mk

archive: prepare
	git -C ${TQEM_PROJECT_ROOT_PATH} submodule update --init --recursive
	tar czf ${TQEM_DEPLOY_PATH}/${BUILD_ARCHIVE} -C ${TQEM_PROJECT_ROOT_PATH} \
		--exclude=artifacts --exclude=deploy --exclude=frontend/container \
		--exclude=cache --exclude-caches-all --exclude-vcs .

deps: archive

deps-extract: frontend-deps-extract backend-deps-extract

upgrade-deps: backend-upgrade frontend-upgrade

clean: backend-clean frontend-clean clean-artifacts

.PHONY: prepare backend frontend empkg archive deps deps-extract upgrade-deps clean
