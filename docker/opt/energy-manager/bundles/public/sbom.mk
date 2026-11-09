# Merges the app SBOMs of every bundle in the deploy tree with the core image SBOM into one
# CycloneDX file per bundle. Run it after the build target.

SBOM_MACHINE = $(shell tqem-device.sh machine ${TQEM_MACHINE})

# The aarch64 image ships the SBOM of its core image next to it. Point the variable to another
# file to merge with a different core image, e.g. a locally built snapshot.
TQEM_CORE_IMAGE_SBOM_FILE ?= /opt/energy-manager/emit/${SBOM_MACHINE}/em-image-core-${SBOM_MACHINE}.sbom-cyclonedx_merged.json
# Components whose purl contains one of these space separated texts are left out
TQEM_SBOM_PURL_EXCLUDES ?=
TQEM_SBOM_OUTPUT_PATH ?= ${TQEM_DEPLOY_DOC_PATH}

sbom:
	sbom.py --bundle-dir '${TQEM_DEPLOY_BIN_PATH}' \
		--core-image-sbom '${TQEM_CORE_IMAGE_SBOM_FILE}' \
		--output-dir '${TQEM_SBOM_OUTPUT_PATH}' \
		--work-dir '${TQEM_TMP_PATH}/sbom' \
		$(foreach text,${TQEM_SBOM_PURL_EXCLUDES},--exclude-purl '${text}')

.PHONY: sbom
