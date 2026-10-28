VERSION_PATH = ${TQEM_ARTIFACTS_DIRNAME}/VERSION.txt
VERSION = $(shell [ -e ${VERSION_PATH} ] && cat ${VERSION_PATH})

# A tag build takes its version from its own tag. git describe picks an annotated tag before a
# lightweight one and the newest first, so a second tag on the commit would win otherwise.
# A TQEM_FORCE_VERSION set by the caller (alpha builds: latest) still wins.
${VERSION_PATH}: artifact-dirs
	TQEM_FORCE_VERSION=$${TQEM_FORCE_VERSION:-$${TQEM_GIT_TAG#v}} tqem-version.sh > ${VERSION_PATH}

version: ${VERSION_PATH}
	$(eval VERSION = $(shell cat ${VERSION_PATH}))

version-clean:
	rm -f ${VERSION_PATH}

.PHONY: version version-clean
