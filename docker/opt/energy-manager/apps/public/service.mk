SERVICE_USER            ?= ${APP_NAME}
SERVICE_GROUP           ?=
SERVICE_WORKING_DIR     ?= /cfglog/apps/${APP_ID}
SERVICE_DEPENDS         ?= mosquitto.service
SERVICE_RESTART         ?= always
SERVICE_RUN_APP_DIR     ?= ${APP_ID}
SERVICE_RUN_DIR         ?= /run/em/apps/${SERVICE_RUN_APP_DIR}
SERVICE_EXEC            ?= ${DIR_APP_ROOT}/bin/${APP_NAME}
SERVICE_OPTS_SOCKET     ?= -listenprotocol unix -listen ${SERVICE_RUN_DIR}/socket -listengroup www
SERVICE_START           ?= ${SERVICE_EXEC} ${SERVICE_OPTS_SOCKET}
SERVICE_FILE            ?= ${APP_NAME}.service

# Prints Key=Value only if the variable is not empty
service_optional = $(if $(strip $($(1))),$(2)=$($(1)))

# No default WantedBy=: em-app-generator evaluates it and would link the app into that target
export define SERVICE_CONTENT
[Unit]
Description=EM app: ${APP_PRETTY_NAME}
$(call service_optional,SERVICE_DEPENDS,Wants)
Before=nginx.service
$(call service_optional,SERVICE_DEPENDS,After)
${SERVICE_EXTRA_UNIT}

[Service]
$(call service_optional,SERVICE_START,ExecStart)
$(call service_optional,SERVICE_USER,User)
$(call service_optional,SERVICE_GROUP,Group)
$(call service_optional,SERVICE_RESTART,Restart)
RestartSec=3
RestartSteps=5
RestartMaxDelaySec=30min
$(call service_optional,SERVICE_WORKING_DIR,WorkingDirectory)
${SERVICE_EXTRA_SERVICE}
$(if $(strip ${SERVICE_EXTRA_INSTALL}),[Install]\n${SERVICE_EXTRA_INSTALL})
endef

# A multi-line variable cannot be passed inline to a recipe (make runs each line as its own
# command), so it is exported and read from the environment. '%b' keeps the escape handling of the
# former echo, e.g. '\n' in SERVICE_EXTRA_* still starts a new line.
empkg-service: empkg-prepare
ifneq ($(SERVICE_BUILD),0)
	printf '%b\n' "$$SERVICE_CONTENT" > ${DIR_PKG_ROOT_APP}/${SERVICE_FILE}
endif

.PHONY: empkg-service
