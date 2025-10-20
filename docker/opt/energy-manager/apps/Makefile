include /opt/energy-manager/common/environment.mk
include /opt/energy-manager/common/version.mk
include /opt/energy-manager/common/artifacts.mk

export APP_ID  ?= ${TQEM_PROJECT_NAME}
APP_NAME       ?= em-app-${APP_ID}

# deployment
TQEM_DEPLOY_SOURCE_PATH ?= ${TQEM_DEPLOY_PATH}
TQEM_DEPLOY_DESTINATION_PATH ?= ${TQEM_APPS_DEPLOY_PATH}/${APP_ID}/${TQEM_GIT_REFERENCE}
include /opt/energy-manager/common/deploy.mk

DIR_APP_ROOT = /apps/installed/${APP_ID}
DIR_PACKAGE  = ${TQEM_ARTIFACTS_PATH}/package

ifndef APP_PRETTY_NAME
$(warning "APP_PRETTY_NAME is not defined.")
endif

ifndef DESCRIPTION
$(warning "DESCRIPTION is not defined.")
endif

BUILD_VARIANT ?= tq
LANG_DEFAULT ?= ${BUILD_VARIANT}
DEFAULT_VARIANT ?= ${BUILD_VARIANT}
EXTRA_BUILD_VARIANTS ?= ${EXTRA_LANG_VARIANTS}
BUILD_VARIANTS ?= $(DEFAULT_VARIANT) $(EXTRA_BUILD_VARIANTS)
LANG_VARIANTS ?= ${BUILD_VARIANTS}
FEATURE_VARIANTS ?= ${DEFAULT_VARIANT}

DIR_BACKEND      ?= ${TQEM_PROJECT_ROOT_PATH}/backend
DIR_FRONTEND     ?= ${TQEM_PROJECT_ROOT_PATH}/frontend
DIR_BACKEND_REL  ?= $(shell basename ${DIR_BACKEND})
DIR_FRONTEND_REL ?= $(shell basename ${DIR_FRONTEND})

# default build flags
FRONTEND_BUILD ?= yarn
BACKEND_BUILD  ?= go-mod

SERVICE_BUILD  ?= $(if $(BACKEND_BUILD),1,0)

PKG_ARCH ?= aarch64

BUILD_ARCHIVE = ${APP_ID}_${VERSION}.tar.gz
FOSS_ARCHIVE  = ${APP_ID}_${VERSION}_foss.tar.gz

# first target = default target
all: build

# set empty targets here and override them in the included files
backend-deps-fetch:
backend-deps-extract:
backend-debug:
backend-release:
backend-finish:
backend-clean:
backend-upgrade:
backend-dbg: backend-debug
	$(MAKE) backend-finish
backend: backend-release
	$(MAKE) backend-finish
frontend-deps-fetch:
frontend-deps-extract:
frontend-release:
frontend-finish:
frontend-foss-archive:
frontend-clean:
frontend-upgrade:
frontend: frontend-release
	$(MAKE) frontend-finish


ifneq ($(FRONTEND_BUILD),)
  include /opt/energy-manager/apps/frontend-$(FRONTEND_BUILD).mk
endif
ifneq ($(BACKEND_BUILD),)
  include /opt/energy-manager/apps/backend-$(BACKEND_BUILD).mk
endif

include /opt/energy-manager/apps/package.mk

prepare: version
	$(MAKE) backend-deps-fetch frontend-deps-fetch

build: backend frontend
	$(MAKE) empkg

archive:
	tar czf ${TQEM_DEPLOY_PATH}/${BUILD_ARCHIVE} -C ${TQEM_PROJECT_ROOT_PATH} \
		--exclude=artifacts --exclude=deploy --exclude=test --exclude=frontend/container \
		--exclude-caches-all --exclude-vcs .

deps: prepare
	$(MAKE) archive

deps-extract: frontend-deps-extract backend-deps-extract

foss-archive: frontend-foss-archive

upgrade-deps: backend-upgrade frontend-upgrade

package-clean:
	rm -rf ${DIR_PACKAGE}

clean: backend-clean frontend-clean clean-artifacts

.PHONY: all prepare build \
	backend-deps-fetch backend-deps-extract backend-debug backend-release \
	backend-finish backend-clean backend-upgrade backend-dbg backend \
	frontend-deps-fetch frontend-deps-extract frontend-release frontend-finish \
	frontend-foss-archive frontend-clean frontend-upgrade frontend \
	archive deps deps-extract foss-archive upgrade-deps package-clean clean
