ifndef TQEM_DEPLOY_SOURCE_PATH
  $(error "TQEM_DEPLOY_SOURCE_PATH is not set")
endif

ifndef TQEM_DEPLOY_DESTINATION_PATH
  $(error "TQEM_DEPLOY_DESTINATION_PATH is not set")
endif

deploy-snapshot:
	tqem-copy.sh ${TQEM_DEPLOY_SOURCE_PATH} ${TQEM_DEPLOY_DESTINATION_PATH} --overwrite

deploy-release:
	tqem-copy-safe.sh ${TQEM_DEPLOY_SOURCE_PATH} ${TQEM_DEPLOY_DESTINATION_PATH}

.PHONY: deploy-snapshot deploy-release
