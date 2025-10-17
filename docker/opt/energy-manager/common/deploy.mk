ifndef TQEM_DEPLOY_SOURCE_PATH
  $(error "TQEM_DEPLOY_SOURCE_PATH is not set")
endif

ifndef TQEM_DEPLOY_DESTINATION_PATH
  $(error "TQEM_DEPLOY_DESTINATION_PATH is not set")
endif

COPY_CMD := tqem-copy.sh ${TQEM_DEPLOY_SOURCE_PATH} ${TQEM_DEPLOY_DESTINATION_PATH}

deploy-snapshot:
	$(COPY_CMD) --overwrite

deploy-release:
	$(COPY_CMD)

.PHONY: deploy-snapshot deploy-release
