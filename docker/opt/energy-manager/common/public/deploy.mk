# By default, artifacts are deployed to a subfolder named after the branch
export TQEM_DEPLOYMENT_SUBDIR ?= ${TQEM_GIT_BRANCH}

# The subfolder ‘master’ is overwritten with ‘main’ in order to have a consistent deployment folder
# structure. As main is the more common default branch name, this also results in a more intuitive
# deployment folder structure.
ifeq ($(TQEM_DEPLOYMENT_SUBDIR),master)
  export TQEM_DEPLOYMENT_SUBDIR = main
endif

# A snapshot deployment uses TQEM_GIT_BRANCH as subfolder in TQEM_DEPLOY_DESTINATION_PATH
deploy-snapshot:
	tqem-copy.sh ${TQEM_DEPLOY_SOURCE_PATH} ${TQEM_DEPLOY_DESTINATION_PATH} --overwrite

# A release deployment uses TQEM_GIT_REFERENCE as subfolder in TQEM_DEPLOY_DESTINATION_PATH
deploy-release:
	$(eval TQEM_DEPLOYMENT_SUBDIR = ${TQEM_GIT_REFERENCE})
	tqem-copy-safe.sh ${TQEM_DEPLOY_SOURCE_PATH} ${TQEM_DEPLOY_DESTINATION_PATH}

.PHONY: deploy-snapshot deploy-release
