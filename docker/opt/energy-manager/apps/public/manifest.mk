ESSENTIAL ?= 0
AUTOSTART ?= 1

ifeq ($(APPCLASS),)
$(warning '${APP_ID}' does not define APPCLASS. Setting 'no-time' as default. Please update Makefile.)
APPCLASS = no-time
endif

MANIFEST_JSON = { \
	id: $$id, \
	version: $$version, \
	arch: $$arch, \
	appclass: (if $$appclass != "" then $$appclass else null end), \
	essential: (if $$essential == 1 then true else null end), \
	autostart: (if $$autostart == 0 then false else null end), \
	variant: (if $$variant != "" then $$variant else null end), \
	min_sys_mem: (if $$sysmem_bytes != "" then $$sysmem_bytes else null end), \
	name: $$name, \
	description: $$description, \
	lang: $$lang \
}

# Requires SERVICE_RUN_DIR, so service.mk must be included before this file
MANIFEST_DEFAULT_OWN_PATHS = \
	"${SERVICE_RUN_DIR}" \
	"/cfglog/apps/${APP_ID}"

# Prevent a recursive reference error by using ':='
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

empkg-manifest: empkg-prepare
	$(eval MANIFEST_EXTRA_JSON = $(shell jq -c --argjson manifest_own_json '$(call args2json,$(MANIFEST_OWN_PATHS))' \
						--argjson manifest_rw_json '$(call args2json,$(MANIFEST_RW_PATHS))' \
						--argjson manifest_ro_json '$(call args2json,$(MANIFEST_RO_PATHS))' \
						-n '${MANIFEST_EXTRA_PATTERN}'))
	$(eval SYSMEM_BYTES = $(shell echo $(MIN_SYS_MEM) | numfmt --from=iec --invalid=ignore))

	jq -nc \
		--arg id '${APP_ID}' \
		--arg version '${VERSION}' \
		--arg arch '${PKG_ARCH}' \
		--arg appclass '${APPCLASS}' \
		--argjson essential '${ESSENTIAL}' \
		--argjson autostart '${AUTOSTART}' \
		--arg variant '${BUILD_VARIANT}' \
		--arg sysmem_bytes '${SYSMEM_BYTES}' \
		--arg name '${APP_PRETTY_NAME}' \
		--arg description '${DESCRIPTION}' \
		--arg lang '${LANG_VARIANT}' \
		--argjson manifest_extra '${MANIFEST_EXTRA_JSON}' \
		'(${MANIFEST_JSON} | with_entries(select(.value != null))) * $$manifest_extra' \
	> ${DIR_PKG_ARCHIVE}/manifest.json

.PHONY: empkg-manifest
