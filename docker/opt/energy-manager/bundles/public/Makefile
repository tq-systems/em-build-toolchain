include /opt/energy-manager/common/public/environment.mk
include /opt/energy-manager/common/public/version.mk
include /opt/energy-manager/common/public/artifacts.mk

# Derive bundle names if not set
BUNDLE_NAME ?= ${TQEM_PROJECT_NAME}
DEVEL_BUNDLE_NAME ?= ${BUNDLE_NAME}-devel
RELEASE_BUNDLE_NAME ?= ${BUNDLE_NAME}-release

# build.mk is included at last to have access to the common makefiles
include /opt/energy-manager/bundles/public/build.mk

# deployment
TQEM_DEPLOY_SOURCE_PATH ?= ${TQEM_DEPLOY_PATH}
TQEM_DEPLOY_DESTINATION_PATH ?= ${TQEM_BUNDLES_DEPLOY_PATH}/${BUNDLE_NAME}/${TQEM_GIT_REFERENCE}
include /opt/energy-manager/common/public/deploy.mk

all: build

prepare: version

clean: clean-artifacts
	rm -rf ${TQEM_DOWNLOADS_PATH} ${TQEM_TMP_PATH}

.PHONY: all prepare clean
