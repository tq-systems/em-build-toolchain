VERSION_PATH = ${TQEM_ARTIFACTS_DIRNAME}/VERSION.txt
VERSION = $(shell [ -e ${VERSION_PATH} ] && cat ${VERSION_PATH})

${VERSION_PATH}: artifact-dirs
	tqem-version.sh > ${VERSION_PATH}

version: ${VERSION_PATH}

version-clean:
	rm -f ${VERSION_PATH}

.PHONY: version version-clean
