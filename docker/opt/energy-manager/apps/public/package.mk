# Service file and manifest generation, service.mk must come first (manifest.mk needs SERVICE_RUN_DIR)
include /opt/energy-manager/apps/public/service.mk
include /opt/energy-manager/apps/public/manifest.mk

APP_FILE_SUFFIX = empkg
# Extends the app ID for the empkg file (e.g. for variants)
APP_ID_SUFFIX ?=

EM_FW_ALLOW_DIRECTION ?= inbound
export define SIMPLE_FW_CONFIG
table inet firewall {
    chain ${EM_FW_ALLOW_DIRECTION} {
        ${EM_FW_ALLOW_PROTOCOL} dport {${EM_FW_ALLOW_PORT}} accept
    }
}
endef

export define README_GENERAL
Application name: ${APP_ID}
Version: ${VERSION}

License information of the application and its dependencies
is provided in the following files:
* The LICENSE file contains the license information for
  the ${APP_ID} application itself.
endef

export define README_GOLANG
* The file ${APP_ID}.golang.manifest contains
  the license specification of the dependent golang packages.
* The file ${APP_ID}.golang.licenses contains
  the license texts of the dependent golang packages.
endef

export define README_FRONTEND_LICENSES
* The file ${APP_ID}.frontend.licenses contains license
  specification and license texts of the dependent node packages.
endef

empkg-prepare:
	$(eval DIR_PKG_ARCHIVE = ${DIR_PACKAGE}/${BUILD_VARIANT}/pkg_archive)
	$(eval DIR_PKG_ROOT_APP = ${DIR_PACKAGE}/${BUILD_VARIANT}/pkg_root${DIR_APP_ROOT})
	mkdir -p ${DIR_PKG_ARCHIVE} ${DIR_PKG_ROOT_APP}

empkg-license: empkg-prepare
	$(eval DIR_PKG_LICENSE = ${DIR_PKG_ROOT_APP}/license)
	install -d ${DIR_PKG_LICENSE}
	install -m 644 LICENSE ${DIR_PKG_LICENSE}

	echo "$$README_GENERAL"      > ${DIR_PKG_LICENSE}/README
	if [ -f ${DIR_PKG_LICENSE}/${APP_ID}.golang.manifest ]; then \
		echo "$$README_GOLANG"  >> ${DIR_PKG_LICENSE}/README; \
	fi
	if [ -f ${DIR_PKG_LICENSE}/${APP_ID}.frontend.licenses ]; then \
		echo "$$README_FRONTEND_LICENSES" >> ${DIR_PKG_LICENSE}/README; \
	fi

empkg-firewall: empkg-prepare
ifdef FILE_EM_FW_CONF
ifneq ($(or $(EM_FW_ALLOW_PROTOCOL),$(EM_FW_ALLOW_PORT)),)
	$(warning "Both FILE_EM_FW_CONF and EM_FW_ALLOW_PROTOCOL/EM_FW_ALLOW_PORT are set. \
	FILE_EM_FW_CONF will override EM_FW_ALLOW_PROTOCOL/EM_FW_ALLOW_PORT settings.")
endif
endif
ifneq ($(FILE_EM_FW_CONF),)
	install -m 644 ${FILE_EM_FW_CONF} ${DIR_PKG_ROOT_APP}/em-fw.conf
else
ifneq ($(and $(EM_FW_ALLOW_PROTOCOL),$(EM_FW_ALLOW_PORT)),)
	echo "$$SIMPLE_FW_CONFIG" > ${DIR_PKG_ROOT_APP}/em-fw.conf
endif
endif

empkg-dbus-conf: empkg-prepare
ifneq ($(FILE_DBUS_CONF),)
	install -m 644 ${FILE_DBUS_CONF} ${DIR_PKG_ROOT_APP}/dbus.conf
endif

# Allow you to customise the profile directory for different variants
EMPKG_PROFILE_SRC_DIR ?= ${DIR_PROFILE}
PKG_DIR_PROFILE = ${DIR_PKG_ROOT_APP}/${DIR_PROFILE_REL}

# This command is used in toolchain extensions
EMPKG_COPY_PROFILE = if test -d ${EMPKG_PROFILE_SRC_DIR}; then \
		install -d ${PKG_DIR_PROFILE}; \
		rsync -a ${EMPKG_PROFILE_SRC_DIR}/ ${PKG_DIR_PROFILE}/; \
	fi

empkg-profile: empkg-prepare
	$(EMPKG_COPY_PROFILE)

empkg-data: empkg-service empkg-license empkg-firewall empkg-dbus-conf empkg-manifest empkg-profile

# Variant subfolder inside bin/, set by variant-aware extensions for non-default variants;
# empty for the default variant and for apps without variants.
PKG_VARIANT_SUBDIR ?=
# The package filename carries this token. Snapshot pipelines use the stable 'latest' because they
# overwrite their target folder in place; local and tag builds keep the version-bearing name plus
# the latest symlink, so the deploy folder still shows which version was built. The real version
# stays in the manifest either way.
PKG_FILE_VERSION ?= $(if ${TQEM_SNAPSHOT_BUILD},latest,${VERSION})
LINK_VERSION ?= latest
EMPKG_TAR := tar --numeric-owner --owner=0 --group=0

empkg-build: empkg-data
	$(eval PKG_FILE = ${APP_ID}${APP_ID_SUFFIX}_${PKG_FILE_VERSION}_${PKG_ARCH}.${APP_FILE_SUFFIX})
	$(eval PKG_BIN_DIR = ${TQEM_DEPLOY_BIN_PATH}/${PKG_VARIANT_SUBDIR})

	mkdir -p ${PKG_BIN_DIR}
	$(EMPKG_TAR) -cJf ${DIR_PKG_ARCHIVE}/data.tar.xz -C ${DIR_PKG_ROOT_APP} .
	$(EMPKG_TAR) -cf ${PKG_BIN_DIR}/${PKG_FILE} -C ${DIR_PKG_ARCHIVE} manifest.json data.tar.xz
	sha256sum ${PKG_BIN_DIR}/${PKG_FILE} | awk '{ print $$1 }' > ${PKG_BIN_DIR}/${PKG_FILE}.sha256

# Only local builds get the symlink; in a pipeline the folder holds exactly one artifact anyway.
ifneq (${TQEM_CI},true)
	$(eval PKG_LINK = ${APP_ID}${APP_ID_SUFFIX}_${LINK_VERSION}_${PKG_ARCH}.${APP_FILE_SUFFIX})
	test '${PKG_FILE}' = '${PKG_LINK}' || ln -sf ${PKG_FILE} ${PKG_BIN_DIR}/${PKG_LINK}
endif

	# LEGACY (remove with next major): flat compat symlinks so consumers of the old flat layout
	# (emit URLs without /bin, app-sdk deploy/*.empkg globs) keep working during the 1-major window.
	ln -sf ${TQEM_BIN_DIRNAME}/${PKG_VARIANT_SUBDIR}${PKG_FILE} ${TQEM_DEPLOY_PATH}/${PKG_FILE}
	ln -sf ${TQEM_BIN_DIRNAME}/${PKG_VARIANT_SUBDIR}${PKG_FILE}.sha256 ${TQEM_DEPLOY_PATH}/${PKG_FILE}.sha256

EMPKG_PREREQS = empkg-build

empkg: $$(EMPKG_PREREQS)

empkg-clean:
	rm -rf ${DIR_PACKAGE}

.PHONY: empkg-prepare empkg-license empkg-firewall empkg-dbus-conf empkg-data \
	empkg-build empkg empkg-clean
