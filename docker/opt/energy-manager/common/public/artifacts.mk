# artifacts.mk: Rules for the artifact directories.

${TQEM_ARTIFACTS_PATH}:
	mkdir -p ${TQEM_ARTIFACTS_PATH}

${TQEM_DEPLOY_PATH}:
	mkdir -p ${TQEM_DEPLOY_PATH}

artifact-dirs: ${TQEM_ARTIFACTS_PATH} ${TQEM_DEPLOY_PATH}

clean-artifacts:
	rm -rf ${TQEM_ARTIFACTS_PATH} ${TQEM_DEPLOY_PATH}

.PHONY: clean-artifacts artifact-dirs
