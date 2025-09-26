DIR_FRONTEND_BUILD = ${DIR_FRONTEND}/dist
DIR_CON_FRONTEND   = ${DIR_FRONTEND}/container/frontend
DIR_CON_APP        = ${DIR_CON_FRONTEND}/apps/${APP_ID}

-include ${DIR_FRONTEND}/.env

# Function to check Yarn version and set parameters
define YARN_INSTALL_CMD
	yarn_version=$$(yarn --version | cut -d. -f1); \
	if [ "$$yarn_version" -gt 1 ]; then \
		yarn install --immutable; \
	else \
		yarn install --frozen-lockfile --ignore-optional; \
	fi
endef

# Function to check Yarn version and run the appropriate audit command
define YARN_AUDIT_CMD
	yarn_version=$$(yarn --version | cut -d. -f1); \
	if [ "$$yarn_version" -gt 1 ]; then \
		yarn npm audit; \
	else \
		yarn audit --groups "dependencies"; \
	fi
endef

yarn-deps:
	cd ${DIR_FRONTEND} && $(YARN_INSTALL_CMD)

yarn-deps-extract:
	rm -rf ./${DIR_FRONTEND_REL}/node_modules && tar xzf ${TQEM_ARTIFACTS_PATH}/${BUILD_ARCHIVE} ./${DIR_FRONTEND_REL}/node_modules

yarn-test-unit: yarn-deps
	cd ${DIR_FRONTEND} && yarn test:unit

yarn-audit:
	cd ${DIR_FRONTEND} && ${YARN_AUDIT_CMD}

yarn-release:
ifdef TOOLCHAIN_VARIANTS_COMPATIBLE
	cd ${DIR_FRONTEND} && ${WEBPACK_EXTRA_ENV} yarn run build --offline
else
	cd ${DIR_FRONTEND} && ${WEBPACK_EXTRA_ENV} yarn run build --offline --output-path ${DIR_FRONTEND_BUILD}
endif

define YARN_PUSH
yarn-push-$(1):
	$(eval DIR_PKG_WWW = ${DIR_PACKAGE}/$(1)/pkg_root${DIR_APP_ROOT}/www)
	$(eval DIR_PKG_LICENSE = ${DIR_PACKAGE}/$(1)/pkg_root${DIR_APP_ROOT}/license)
	mkdir -p ${DIR_PKG_WWW} ${DIR_PKG_LICENSE}

ifdef TOOLCHAIN_VARIANTS_COMPATIBLE
	${eval DIR_FRONTEND_BUILD_VARIANT = ${DIR_FRONTEND_BUILD}/$(1)}
	cp -rf ${DIR_FRONTEND_BUILD_VARIANT}/* ${DIR_PKG_WWW}
else
	${eval DIR_FRONTEND_BUILD_VARIANT = ${DIR_FRONTEND_BUILD}}
	cp -rf ${DIR_FRONTEND_BUILD_VARIANT}/* ${DIR_PKG_WWW}
# copy only one language file
	rm -f ${DIR_PKG_WWW}/i18n/*
	cp ${DIR_FRONTEND_BUILD_VARIANT}/i18n/$(1).js ${DIR_PKG_WWW}/i18n/lang.js
endif
	mv ${DIR_PKG_WWW}/ThirdPartyNotice.txt ${DIR_PKG_LICENSE}/${APP_ID}.frontend.licenses
endef
$(foreach variant,$(BUILD_VARIANTS),$(eval $(call YARN_PUSH,$(variant))))

yarn-setup:
	yarn install
	./setup.js -i '${APP_ID}'

yarn-serve: yarn-setup yarn-release
	@{ if [ -z "$(BRANDING)" ]; then read -p ">>>>>>>>>>>>>>>> Enter branding: " branding; else branding=${BRANDING}; fi; }; \
	{ if [ -z "$(TARGET)" ]; then read -p ">>>>>>>>>>>>>>>> Enter target: " target; else target=${TARGET}; fi; }; \
	mkdir -p ${DIR_CON_APP};\
	cp -r ${DIR_FRONTEND_BUILD}/* ${DIR_CON_APP};\
	cd ${DIR_CON_FRONTEND} && BRANDING=$${branding} TARGET=$${target} yarn run dev

yarn-foss-archive:
	webpack-foss-archive.sh ${BUILD_ARCHIVE} ${FOSS_ARCHIVE}

yarn-clean:
	rm -rf ${DIR_FRONTEND}/node_modules ${DIR_FRONTEND_BUILD} node_modules

yarn-upgrade:
	cd ${DIR_FRONTEND} && yarn upgrade
	$(MAKE) yarn-outdated

yarn-outdated:
	@echo "Checking for outdated packages with 'yarn outdated'. This lists packages that can be updated."
	cd ${DIR_FRONTEND} && yarn outdated || true

frontend-prepare:      yarn-deps
frontend-deps-fetch:   yarn-deps
frontend-deps-extract: yarn-deps-extract
frontend-release:      yarn-release
frontend-finish:       $(foreach variant,$(BUILD_VARIANTS), yarn-push-$(variant))
frontend-foss-archive: yarn-foss-archive
frontend-clean:        yarn-clean
frontend-upgrade:      yarn-upgrade

.PHONY: yarn-deps yarn-deps-extract yarn-test-unit yarn-audit yarn-release \
	yarn-setup yarn-serve yarn-foss-archive yarn-clean yarn-upgrade yarn-outdated \
