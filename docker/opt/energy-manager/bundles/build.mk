# Set the em4xx (hw0200) machine by default
TQEM_MACHINES ?= em4xx

BASE_SPEC     ?= /opt/energy-manager/emit/base-stable.yml
DEFAULT_SPEC  ?= ${DEVEL_BUNDLE_NAME}.yml
EMIT_OPTIONS  ?= --bundle-spec ${DEFAULT_SPEC}
EMIT_BASE_ARGS = --arch ${PKG_ARCH} --bundle-spec ${BASE_SPEC} ${EMIT_OPTIONS}

RAUC_KEY      ?= /opt/energy-manager/emit/cert/key.devel.pem
RAUC_CERT     ?= /opt/energy-manager/emit/cert/ca.devel.pem
RAUC_KEYRING  ?= ${RAUC_KEY}

BUNDLE_BUILD_NAME ?= ${DEVEL_BUNDLE_NAME}

BUNDLE_SUFFIX = raucb

EMIT_BASE_BUILD_ARGS = \
	--machine ${MACHINE} \
	--device-type ${DEVICE_TYPE} \
	$(if ${DEVICE_SUBTYPE},--device-subtype '${DEVICE_SUBTYPE}') \
	--manufacturer-id '${MANUFACTURER_ID}' \
	$(if ${PRODUCT_ID},--product-id '${PRODUCT_ID}') \
	--rauc-key ${RAUC_KEY} \
	--rauc-cert ${RAUC_CERT} \
	--rauc-keyring ${RAUC_KEYRING} \
	--core-image ${FILE_CORE_IMAGE} \
	--image-name ${DEVEL_BUNDLE_NAME} \
	--bundle-version ${VERSION} \
	--output-bundle ${TQEM_DEPLOY_PATH}/${BUNDLE_FILE}

# TBD: Fix caching with emit
# $(if ${TQEM_APPS_CACHE_PATH},--download-dir '${TQEM_APPS_CACHE_PATH}')

ifdef EM_BUNDLE_MIGRATION_EXEC
MIGRATION_ARGS = --migration-exec ${EM_BUNDLE_MIGRATION_EXEC}
endif

ifdef EM_BUNDLE_DISABLE_FIREWALL
FIREWALL_ARGS = --disable-firewall
endif

bootloader-arg = --bootloader '$(word 1,$(1))' '/opt/energy-manager/emit/${MACHINE}/$(word 2,$(1))'
bootloader-args = $(foreach bootloader,$(1),$(call bootloader-arg,$(subst =, ,$(bootloader))))

define BUNDLE_BUILD
bundle-build-$(1):
	$(eval DEVICE_TYPE     = $(shell tqem-device.sh type $(1)))
	$(eval DEVICE_SUBTYPE  = $(shell tqem-device.sh subtype $(1)))
	$(eval MACHINE         = $(shell tqem-device.sh machine $(1)))
	$(eval MANUFACTURER_ID = 0x5233)
	$(eval PRODUCT_ID      = $(shell tqem-device.sh product-id $(1)))
	$(eval PKG_ARCH        = $(shell tqem-device.sh arch $(1)))
	$(eval BOOTLOADERS     = $(shell tqem-device.sh bootloaders $(1)))

	$(eval FILE_CORE_IMAGE = /opt/energy-manager/emit/${MACHINE}/em-image-core-${MACHINE}.tar)
	$(eval BUNDLE_PREFIX  = ${BUNDLE_BUILD_NAME}-${DEVICE_TYPE})
	$(eval BUNDLE_FILE    = ${BUNDLE_PREFIX}-sw${VERSION}.${BUNDLE_SUFFIX})

	env SSL_CERT_FILE=/etc/ssl/certs/ca-certificates.crt \
		emit ${EMIT_BASE_ARGS} download

	$(eval EMIT_BUILD_ARGS = $(EMIT_BASE_BUILD_ARGS) $(MIGRATION_ARGS) $(FIREWALL_ARGS))

	emit ${EMIT_BASE_ARGS} build ${EMIT_BUILD_ARGS} $(call bootloader-args,$(BOOTLOADERS))
endef
$(foreach machine,${TQEM_MACHINES},$(eval $(call BUNDLE_BUILD,${machine})))

build: $(foreach machine,${TQEM_MACHINES}, bundle-build-${machine})
