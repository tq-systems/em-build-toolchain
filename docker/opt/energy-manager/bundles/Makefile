include /opt/energy-manager/common/environment.mk
include /opt/energy-manager/common/version.mk
include /opt/energy-manager/common/artifacts.mk

# Derive bundle names if not set
BUNDLE_NAME ?= ${TQEM_PROJECT_NAME}
DEVEL_BUNDLE_NAME ?= ${BUNDLE_NAME}-devel
RELEASE_BUNDLE_NAME ?= ${BUNDLE_NAME}-release

# build.mk is included at last to have access to the common makefiles
include /opt/energy-manager/bundles/build.mk

all: build cache

cache:
	tqem-copy.sh ${TQEM_DOWNLOADS_PATH} ${TQEM_APPS_CACHE_PATH} --overwrite

prepare: version

deploy:
	tqem-copy.sh ${TQEM_DEPLOY_PATH} ${TQEM_BUNDLES_DEPLOY_PATH}/${BUNDLE_NAME}/${TQEM_GIT_REFERENCE}

clean: clean-artifacts
	rm -rf ${TQEM_DOWNLOADS_PATH} ${TQEM_TMP_PATH}

.PHONY: all cache prepare deploy clean
