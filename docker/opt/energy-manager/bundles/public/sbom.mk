# Merges the app SBOMs of every bundle in the deploy tree with the core image SBOM into one
# CycloneDX file per bundle. Run it after the build target.

# TQEM_MACHINE names the device (e.g. em4xx), the path below needs its Yocto machine (em-aarch64)
SBOM_MACHINE = $(shell tqem-device.sh machine ${TQEM_MACHINE})

# The aarch64 image ships the SBOM of its core image next to it. Point the variable to another
# file to merge with a different core image, e.g. a locally built snapshot.
TQEM_CORE_IMAGE_SBOM_FILE ?= /opt/energy-manager/emit/${SBOM_MACHINE}/em-image-core-${SBOM_MACHINE}.sbom-cyclonedx_merged.json
# Components whose purl contains one of these space separated texts are left out
TQEM_SBOM_PURL_EXCLUDES ?=
TQEM_SBOM_OUTPUT_PATH ?= ${TQEM_DEPLOY_DOC_PATH}
# The app SBOMs are a build input, not an artifact of the bundle, so they stay out of deploy
TQEM_APP_SBOM_PATH ?= ${TQEM_ARTIFACTS_PATH}/app-sboms

# Apps deploy their SBOM below doc/ instead of shipping it inside the package, the library copies
# them out of the mounted deploy tree. It hangs on the build, because only there the bundle specs
# of this bundle are set. Like the app packages it is a directory target, so a second build reuses
# what is there.
build: ${TQEM_APP_SBOM_PATH}

${TQEM_APP_SBOM_PATH}:
	tqem-fetch-app-sboms --bundle-spec '${BASE_SPEC}' ${EMIT_OPTIONS} \
		--output-dir '${TQEM_APP_SBOM_PATH}'

sbom:
	tqem-bundle-sbom --bundle-dir '${TQEM_DEPLOY_BIN_PATH}' \
		--bundle-name '${BUNDLE_NAME}' \
		--app-sbom-dir '${TQEM_APP_SBOM_PATH}' \
		--core-image-sbom '${TQEM_CORE_IMAGE_SBOM_FILE}' \
		--output-dir '${TQEM_SBOM_OUTPUT_PATH}' \
		--work-dir '${TQEM_TMP_PATH}/sbom' \
		$(foreach text,${TQEM_SBOM_PURL_EXCLUDES},--exclude-purl '${text}')

.PHONY: sbom
