# By default, artifacts are deployed to a subfolder named after the git reference
export TQEM_DEPLOYMENT_SUBDIR ?= ${TQEM_GIT_REFERENCE}

# The subfolder ‘master’ is overwritten with ‘main’ in order to have a consistent deployment folder
# structure. As main is the more common default branch name, this also results in a more intuitive
# deployment folder structure.
ifeq ($(TQEM_DEPLOYMENT_SUBDIR),master)
  export TQEM_DEPLOYMENT_SUBDIR = main
endif

deploy-snapshot:
	tqem-copy.sh ${TQEM_DEPLOY_SOURCE_PATH} ${TQEM_DEPLOY_DESTINATION_PATH} --overwrite

deploy-release:
	$(eval TQEM_BUILD_TYPE_DIRNAME = ${TQEM_RELEASES_DIRNAME})
	tqem-copy-safe.sh ${TQEM_DEPLOY_SOURCE_PATH} ${TQEM_DEPLOY_DESTINATION_PATH}

.PHONY: deploy-snapshot deploy-release
