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

## Access to files that other units create at runtime
RUNTIME_RW_PATHS        ?=
RUNTIME_RO_PATHS        ?=
RUNTIME_DEPENDS         ?=

# One tmpfiles.d line for path $(1) with permissions $(2). 'a+' adds an ACL entry for the service
# user and keeps the existing entries. 'm::rwx' opens the ACL mask, which would otherwise limit the
# new entry. The line ends with '\\n': printf '%b' in empkg-service writes that as the two
# characters '\n', which systemd decodes to a line break in SetCredential=.
runtime_acl_line = a+ $(1) - - - - u:${SERVICE_USER}:$(2),m::rwx\\n

# rwx for every RW path
RUNTIME_RW_LINES        = $(foreach p,${RUNTIME_RW_PATHS},$(call runtime_acl_line,$(p),rwx))
# r-x for every RO path that is not already in the RW list
RUNTIME_RO_LINES        = $(foreach p,$(filter-out ${RUNTIME_RW_PATHS},${RUNTIME_RO_PATHS}),$(call runtime_acl_line,$(p),r-x))

# All lines as one value. foreach puts a space between its results; the subst removes it again,
# so that no line starts with a blank.
RUNTIME_TMPFILES_LINES  = $(subst \\n ,\\n,$(strip ${RUNTIME_RW_LINES} ${RUNTIME_RO_LINES}))

# Value for SetCredential=: hands the lines to the service as the credential 'tmpfiles.extra'.
# Empty without RUNTIME_*_PATHS, so service_optional leaves the setting out.
RUNTIME_CREDENTIAL      = $(if ${RUNTIME_TMPFILES_LINES},tmpfiles.extra:${RUNTIME_TMPFILES_LINES})

# One --prefix option per path. It limits systemd-tmpfiles to these paths, so that it does not
# apply the rest of the system's tmpfiles.d configuration.
RUNTIME_TMPFILES_PREFIX = $(addprefix --prefix=,${RUNTIME_RW_PATHS} ${RUNTIME_RO_PATHS})

# Value for ExecStartPre=: runs systemd-tmpfiles as root ('+') before the app starts. It reads the
# credential 'tmpfiles.extra' like an extra configuration file and sets the ACL entries.
# Empty without RUNTIME_*_PATHS, so service_optional leaves the setting out.
RUNTIME_EXEC_START_PRE  = $(if ${RUNTIME_TMPFILES_LINES},+/usr/bin/systemd-tmpfiles --create ${RUNTIME_TMPFILES_PREFIX})

# Prints Key=Value only if the variable is not empty
service_optional = $(if $(strip $($(1))),$(2)=$($(1)))

# No default WantedBy=: em-app-generator evaluates it and would link the app into that target
export define SERVICE_CONTENT
[Unit]
Description=EM app: ${APP_PRETTY_NAME}
$(call service_optional,SERVICE_DEPENDS,Wants)
Before=nginx.service
$(call service_optional,SERVICE_DEPENDS,After)
$(call service_optional,RUNTIME_DEPENDS,Requires)
$(call service_optional,RUNTIME_DEPENDS,After)
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
$(call service_optional,RUNTIME_CREDENTIAL,SetCredential)
$(call service_optional,RUNTIME_EXEC_START_PRE,ExecStartPre)
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
