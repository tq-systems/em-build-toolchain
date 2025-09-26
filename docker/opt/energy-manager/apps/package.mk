TQEM_APP_SUFFIX = empkg

LINK_SUFFIX ?= latest

ESSENTIAL ?= 0
AUTOSTART ?= 1

SERVICE_WORKING_DIR = /cfglog/apps/${APP_ID}
SERVICE_RUN_DIR     = /run/em/apps/${APP_ID}
SERVICE_FILE        = ${APP_NAME}.service
SERVICE_EXEC        = ${DIR_APP_ROOT}/bin/${APP_NAME}
SERVICE_OPTS_SOCKET = -listenprotocol unix -listen ${SERVICE_RUN_DIR}/socket -listengroup www
SERVICE_START       = ${SERVICE_EXEC} ${SERVICE_OPTS_SOCKET}
SERVICE_DEPENDS     = mosquitto.service

export define SERVICE_CONTENT
[Unit]
Description=EM app: ${APP_PRETTY_NAME}
Wants=${SERVICE_DEPENDS}
Before=nginx.service
After=${SERVICE_DEPENDS}
${SERVICE_EXTRA_UNIT}

[Service]
ExecStart=${SERVICE_START}
Restart=always
RestartSec=3
RestartSteps=5
RestartMaxDelaySec=30min
WorkingDirectory=${SERVICE_WORKING_DIR}
${SERVICE_EXTRA_SERVICE}
endef


MANIFEST_JSON = { \
	id: $$$$id, \
	version: $$$$version, \
	arch: $$$$arch, \
	appclass: (if $$$$appclass != "" then $$$$appclass else null end), \
	essential: (if $$$$essential == 1 then true else null end), \
	autostart: (if $$$$autostart == 0 then false else null end), \
	variant: (if $$$$variant != "" then $$$$variant else null end), \
	name: $$$$name, \
	description: $$$$description, \
	lang: $$$$lang \
}

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

define EMPKG_PREPARE
empkg-prepare-$(1):
	$(eval DIR_PKG_ARCHIVE = ${DIR_PACKAGE}/$(1)/pkg_archive)
	$(eval DIR_PKG_LICENSE = ${DIR_PACKAGE}/$(1)/pkg_root${DIR_APP_ROOT}/license)
	mkdir -p ${DIR_PKG_ARCHIVE} ${DIR_PKG_LICENSE}
endef
$(foreach variant,$(BUILD_VARIANTS),$(eval $(call EMPKG_PREPARE,$(variant))))

define EMPKG_SERVICE
empkg-service-$(1): empkg-prepare-$(1)
ifneq ($(SERVICE_BUILD),0)
	echo "$$$$SERVICE_CONTENT" > ${DIR_PACKAGE}/$(1)/pkg_root${DIR_APP_ROOT}/${SERVICE_FILE}
endif
endef
$(foreach variant,$(BUILD_VARIANTS),$(eval $(call EMPKG_SERVICE,$(variant))))

define EMPKG_LICENSE
empkg-license-$(1): empkg-prepare-$(1)
	$(eval DIR_PKG_LICENSE = ${DIR_PACKAGE}/$(1)/pkg_root${DIR_APP_ROOT}/license)
	cp -f  LICENSE ${DIR_PKG_LICENSE}

	echo "$$$$README_GENERAL"      > ${DIR_PKG_LICENSE}/README
	if [ -f ${DIR_PKG_LICENSE}/${APP_ID}.golang.manifest ]; then \
		echo "$$$$README_GOLANG"  >> ${DIR_PKG_LICENSE}/README; \
	fi
	if [ -f ${DIR_PKG_LICENSE}/${APP_ID}.frontend.licenses ]; then \
		echo "$$$$README_FRONTEND_LICENSES" >> ${DIR_PKG_LICENSE}/README; \
	fi
endef
$(foreach variant,$(BUILD_VARIANTS),$(eval $(call EMPKG_LICENSE,$(variant))))

MANIFEST_DEFAULT_OWN_PATHS = \
	"/run/em/apps/${APP_ID}" \
	"/cfglog/apps/${APP_ID}"

MANIFEST_OWN_PATHS := ${MANIFEST_DEFAULT_OWN_PATHS} ${MANIFEST_OWN_PATHS}
MANIFEST_RW_PATHS ?=
MANIFEST_RO_PATHS ?=

MANIFEST_EXTRA_PATTERN = { \
"permissions": { \
    "own": $$manifest_own_json, \
    "rw": $$manifest_rw_json, \
    "ro": $$manifest_ro_json  \
  } \
}
# transform bash-lists to json
args2json = $(shell jq -nc '$$ARGS.positional' --args $(1))

ifeq ($(APPCLASS),)
$(warning '${APP_ID}' does not define APPCLASS. Please update Makefile.)
endif

define EMPKG_MANIFEST
empkg-manifest-$(1): empkg-prepare-$(1)
	$(eval DIR_PKG_ARCHIVE = ${DIR_PACKAGE}/$(1)/pkg_archive)
	$(eval BUILD_VARIANT_LANG = $(if ${TOOLCHAIN_VARIANTS_COMPATIBLE},$(shell app-variant-get.py language -v $(1)),$(1)))
	$(eval MANIFEST_EXTRA_JSON = $(shell jq --argjson manifest_own_json '$(call args2json,$(MANIFEST_OWN_PATHS))' \
						--argjson manifest_rw_json '$(call args2json,$(MANIFEST_RW_PATHS))' \
						--argjson manifest_ro_json '$(call args2json,$(MANIFEST_RO_PATHS))' \
						-n '${MANIFEST_EXTRA_PATTERN}'))

	jq -nc \
		--arg id '${APP_ID}' \
		--arg version '${VERSION}' \
		--arg arch '${PKG_ARCH}' \
		--arg appclass '${APPCLASS}' \
		--argjson essential '${ESSENTIAL}' \
		--argjson autostart '${AUTOSTART}' \
		--arg variant '$(1)' \
		--arg name '${APP_PRETTY_NAME}' \
		--arg description '${DESCRIPTION}' \
		--arg lang '${BUILD_VARIANT_LANG}' \
		--argjson manifest_extra '$${MANIFEST_EXTRA_JSON}' \
		'(${MANIFEST_JSON} | with_entries(select(.value != null))) * $$$$manifest_extra' \
	> ${DIR_PKG_ARCHIVE}/manifest.json
endef
$(foreach variant,$(BUILD_VARIANTS),$(eval $(call EMPKG_MANIFEST,$(variant))))

ifdef EM_FW_ALLOW_PROTOCOL
ifdef EM_FW_ALLOW_PORT
ifdef FILE_EM_FW_CONF
$(warning "Both EM_FW_ALLOW_PROTOCOL/EM_FW_ALLOW_PORT and FILE_EM_FW_CONF are set. \
FILE_EM_FW_CONF will override EM_FW_ALLOW_PROTOCOL/EM_FW_ALLOW_PORT settings.")
endif
endif
endif

define EMPKG_DATA
empkg-data-$(1): empkg-service-$(1) empkg-license-$(1)
ifdef EM_FW_ALLOW_PROTOCOL
ifdef EM_FW_ALLOW_PORT
	install -d ${DIR_PACKAGE}/$(1)/pkg_root${DIR_APP_ROOT}
	echo "$$$$SIMPLE_FW_CONFIG" > ${DIR_PACKAGE}/$(1)/pkg_root${DIR_APP_ROOT}/em-fw.conf
endif
endif
ifneq ($(FILE_EM_FW_CONF),)
	install -d ${DIR_PACKAGE}/$(1)/pkg_root${DIR_APP_ROOT}
	install -m 644 ${FILE_EM_FW_CONF} ${DIR_PACKAGE}/$(1)/pkg_root${DIR_APP_ROOT}/em-fw.conf
endif
ifneq ($(FILE_DBUS_CONF),)
	install -d ${DIR_PACKAGE}/$(1)/pkg_root${DIR_APP_ROOT}
	install -m 644 ${FILE_DBUS_CONF} ${DIR_PACKAGE}/$(1)/pkg_root${DIR_APP_ROOT}/dbus.conf
endif
endef
$(foreach variant,$(BUILD_VARIANTS),$(eval $(call EMPKG_DATA,$(variant))))

define EMPKG_BUILD
empkg-build-$(1): empkg-data-$(1) empkg-manifest-$(1)
	$(eval VARIANT_SUFFIX = $(if $(filter-out ${DEFAULT_VARIANT},$(1)),-$(1)))

	$(eval PKG_FILE  = ${APP_ID}${VARIANT_SUFFIX}_${VERSION}_${PKG_ARCH}.${TQEM_APP_SUFFIX})
	$(eval PKG_LINK  = ${APP_ID}${VARIANT_SUFFIX}_${LINK_SUFFIX}_${PKG_ARCH}.${TQEM_APP_SUFFIX})
	$(eval DIR_PKG_ARCHIVE = ${DIR_PACKAGE}/$(1)/pkg_archive)

	tar --numeric-owner --owner=0 --group=0 -cJf ${DIR_PKG_ARCHIVE}/data.tar.xz -C ${DIR_PACKAGE}/$(1)/pkg_root${DIR_APP_ROOT} .
	tar --numeric-owner --owner=0 --group=0 -cf ${TQEM_DEPLOY_PATH}/${PKG_FILE} -C ${DIR_PKG_ARCHIVE} manifest.json data.tar.xz
	sha256sum ${TQEM_DEPLOY_PATH}/${PKG_FILE} | awk '{ print $$$$1 }' > ${TQEM_DEPLOY_PATH}/${PKG_FILE}.sha256
	ln -sf ${PKG_FILE} ${TQEM_DEPLOY_PATH}/${PKG_LINK}

endef
$(foreach variant,$(BUILD_VARIANTS),$(eval $(call EMPKG_BUILD,$(variant))))

empkg: $(foreach variant,$(BUILD_VARIANTS), empkg-build-$(variant))

empkg-clean:
	rm -rf ${DIR_PACKAGE}

.PHONY: empkg empkg-clean
