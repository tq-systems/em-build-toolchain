SERVICE_USER            ?= ${APP_NAME}
SERVICE_WORKING_DIR     = /cfglog/apps/${APP_ID}
SERVICE_RUN_APP_DIR     ?= ${APP_ID}
SERVICE_RUN_DIR         = /run/em/apps/${SERVICE_RUN_APP_DIR}
SERVICE_FILE            = ${APP_NAME}.service
SERVICE_EXEC            = ${DIR_APP_ROOT}/bin/${APP_NAME}
SERVICE_OPTS_SOCKET     = -listenprotocol unix -listen ${SERVICE_RUN_DIR}/socket -listengroup www
SERVICE_START           = ${SERVICE_EXEC} ${SERVICE_OPTS_SOCKET}
SERVICE_DEPENDS         = mosquitto.service
SERVICE_INSTALL_SECTION = $(if $(strip $(SERVICE_EXTRA_INSTALL)),\n[Install]\n$(SERVICE_EXTRA_INSTALL))

export define SERVICE_CONTENT
[Unit]
Description=EM app: ${APP_PRETTY_NAME}
Wants=${SERVICE_DEPENDS}
Before=nginx.service
After=${SERVICE_DEPENDS}
${SERVICE_EXTRA_UNIT}

[Service]
ExecStart=${SERVICE_START}
User=${SERVICE_USER}
Restart=always
RestartSec=3
RestartSteps=5
RestartMaxDelaySec=30min
WorkingDirectory=${SERVICE_WORKING_DIR}
${SERVICE_EXTRA_SERVICE}
$(SERVICE_INSTALL_SECTION)
endef

empkg-service: empkg-prepare
ifneq ($(SERVICE_BUILD),0)
	echo "$$SERVICE_CONTENT" > ${DIR_PKG_ROOT_APP}/${SERVICE_FILE}
endif

.PHONY: empkg-service
