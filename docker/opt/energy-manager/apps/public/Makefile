include /opt/energy-manager/common/public/environment.mk
include /opt/energy-manager/common/public/artifacts.mk
include /opt/energy-manager/common/public/version.mk

include /opt/energy-manager/apps/public/package.mk

export APP_ID  ?= ${TQEM_PROJECT_NAME}
APP_NAME       ?= em-app-${APP_ID}

# Deployment
TQEM_DEPLOY_SOURCE_PATH ?= ${TQEM_DEPLOY_PATH}
TQEM_DEPLOY_DESTINATION_PATH ?= ${TQEM_APPS_DEPLOY_PATH}/${APP_ID}/${TQEM_GIT_REFERENCE}
include /opt/energy-manager/common/public/deploy.mk

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
DIR_BACKEND      ?= ${TQEM_PROJECT_ROOT_PATH}/${DIR_BACKEND_REL}
DIR_FRONTEND     ?= ${TQEM_PROJECT_ROOT_PATH}/${DIR_FRONTEND_REL}

# Default build flags
FRONTEND_BUILD ?= yarn
BACKEND_BUILD  ?= go-mod

SERVICE_BUILD  ?= $(if $(BACKEND_BUILD),1,0)

PKG_ARCH ?= aarch64

BUILD_ARCHIVE = ${APP_ID}_${VERSION}.tar.gz

# First target = default target
all: build

# Set empty targets here and override them in the included files
backend-deps-fetch:
backend-deps-extract:
backend-debug-build:
backend-release-build:
backend-finish:
backend-clean:
backend-upgrade:
backend-debug: backend-debug-build
	$(MAKE) backend-finish
backend-release: backend-release-build
	$(MAKE) backend-finish
backend: backend-release
frontend-deps-fetch:
frontend-deps-extract:
frontend-release:
frontend-finish:
frontend-clean:
frontend-upgrade:
frontend: frontend-release
	$(MAKE) frontend-finish

ifeq ($(FRONTEND_BUILD),yarn)
  include /opt/energy-manager/apps/public/frontend-yarn.mk
endif
ifeq ($(BACKEND_BUILD),go-mod)
  include /opt/energy-manager/apps/public/backend-go-mod.mk
endif

prepare: version
	$(MAKE) backend-deps-fetch frontend-deps-fetch

build: backend-release frontend
	$(MAKE) empkg

all-debug: backend-debug frontend
	$(MAKE) empkg

archive:
	tar czf ${TQEM_DEPLOY_PATH}/${BUILD_ARCHIVE} -C ${TQEM_PROJECT_ROOT_PATH} \
		--exclude=artifacts --exclude=deploy --exclude=test --exclude=frontend/container \
		--exclude-caches-all --exclude-vcs .

deps: prepare
	$(MAKE) archive

deps-extract: frontend-deps-extract backend-deps-extract

upgrade-deps: backend-upgrade frontend-upgrade

package-clean:
	rm -rf ${DIR_PACKAGE}

clean: backend-clean frontend-clean clean-artifacts

.PHONY: all \
	backend-deps-fetch backend-deps-extract backend-debug-build backend-release-build \
	backend-finish backend-clean backend-upgrade backend-debug backend-release backend \
	frontend-deps-fetch frontend-deps-extract frontend-release frontend-finish \
	frontend-clean frontend-upgrade frontend
	prepare build all-debug \
	archive deps deps-extract upgrade-deps package-clean clean
